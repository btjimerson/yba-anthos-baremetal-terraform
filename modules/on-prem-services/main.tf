locals {
  ssh_command = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${var.ssh_key_path} ${var.username}@${var.bastion_ip}"
  unix_home   = var.username == "root" ? "/root" : "/home/${var.username}"
}

// Create a service account token for remotely administering in GKE
resource "null_resource" "create_service_account_token" {
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl create serviceaccount -n kube-system remote-admin",
      "kubectl create clusterrolebinding remote-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:remote-admin",
      "kubectl apply -f - <<EOF",
      "apiVersion: v1",
      "kind: Secret",
      "metadata:",
      "  name: remote-admin-token",
      "  namespace: kube-system",
      "  annotations:",
      "    kubernetes.io/service-account.name: remote-admin",
      "type: kubernetes.io/service-account-token",
      "EOF"
    ]
  }
}

// Set the remote admin token data
data "external" "remote_admin_token" {
  depends_on = [null_resource.create_service_account_token]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(${local.ssh_command} kubectl -n kube-system get secret remote-admin-token -o jsonpath='{.data.token}')\" '{$content}'"
  ]
}

// Set the remote kubeconfig data
data "external" "remote_kubeconfig" {
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(${local.ssh_command} cat ${local.unix_home}/.kube/config)\" '{$content}'"
  ]
}

// Create the namespace for Yugabyte nodes
resource "null_resource" "create_yugabyte_nodes_namespace" {
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl create namespace ${var.yugabyte_nodes_namespace}",
      "kubectl label namespace ${var.yugabyte_nodes_namespace} istio-injection=enabled"
    ]
  }
}

// Download Istio
resource "null_resource" "download_istio" {
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${var.istio_version} sh -"
    ]
  }
}

// Create Istio root namespace
resource "null_resource" "create_istio_namespace" {
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl create namespace ${var.istio_namespace}"
    ]
  }
}

// Label istio namespace
resource "null_resource" "label_istio_namespace" {
  depends_on = [null_resource.create_istio_namespace]
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl label namespace istio-system topology.istio.io/network=${var.istio_network_name}"
    ]
  }
}

//Create certs secret
resource "null_resource" "create_istio_certs_secret" {
  depends_on = [null_resource.create_istio_namespace]
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      kubectl create secret generic cacerts -n ${var.istio_namespace} \
        --from-literal=ca-cert.pem='${var.istio_ca_cert}' \
        --from-literal=ca-key.pem='${var.istio_ca_key}' \
        --from-literal=root-cert.pem='${var.istio_root_cert}' \
        --from-literal=cert-chain.pem='${var.istio_cert_chain}'
      EOT
    ]
  }
}

// Apply Istio Operator configuration
resource "null_resource" "apply_istio_cluster_configuration" {
  depends_on = [null_resource.create_istio_certs_secret]
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      cat <<EOF | istio-${var.istio_version}/bin/istioctl install -y -f -
      apiVersion: install.istio.io/v1alpha1
      kind: IstioOperator
      spec:
        meshConfig:
          defaultConfig:
            proxyMetadata:
              ISTIO_META_DNS_CAPTURE: "true"
              ISTIO_META_DNS_AUTO_ALLOCATE: "true"
        values:
          global:
            meshID: ${var.istio_mesh_name}
            multiCluster:
              clusterName: ${var.istio_cluster_name}
            network: ${var.istio_network_name}
      EOF
      EOT
    ]
  }
}

// Apply east-west gateway
resource "null_resource" "apply_east_west_gateway" {
  depends_on = [null_resource.apply_istio_cluster_configuration]
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      istio-${var.istio_version}/samples/multicluster/gen-eastwest-gateway.sh \
        --mesh ${var.istio_mesh_name} \
        --cluster ${var.istio_cluster_name} \
        --network ${var.istio_network_name} | \
        istio-${var.istio_version}/bin/istioctl install -y -f -
      EOT
    ]
  }
}

// Expose istio services
resource "null_resource" "expose_istio_services" {
  depends_on = [null_resource.apply_east_west_gateway]
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      kubectl apply -n ${var.istio_namespace} -f istio-${var.istio_version}/samples/multicluster/expose-services.yaml
      EOT
    ]
  }
}

// Get the ingress gateway IP address
data "external" "remote_ingress_ip" {
  depends_on = [null_resource.expose_istio_services]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(${local.ssh_command} kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')\" '{$content}'"
  ]
}

// Create a secret to connect to the cluster
data "external" "cluster_secret" {
  depends_on = [null_resource.apply_east_west_gateway]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(${local.ssh_command} istio-${var.istio_version}/bin/istioctl x create-remote-secret --name=${var.istio_cluster_name})\" '{$content}'"
  ]
}





