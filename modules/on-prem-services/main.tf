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

data "external" "remote_admin_token" {
  depends_on = [null_resource.create_service_account_token]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(${local.ssh_command} kubectl -n kube-system get secret remote-admin-token -o jsonpath='{.data.token}')\" '{$content}'"
  ]
}

data "external" "remote_kubeconfig" {
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(${local.ssh_command} cat ${local.unix_home}/.kube/config)\" '{$content}'"
  ]
}

// Create the inlets client deployment
resource "null_resource" "create_tunnel_client" {
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f - <<EOF",
      "apiVersion: apps/v1",
      "kind: Deployment",
      "metadata:",
      "  name: ${var.location_name}-inlets-client",
      "spec:",
      "  replicas: 1",
      "  selector:",
      "    matchLabels:",
      "      app: ${var.location_name}-inlets-client",
      "  template:",
      "    metadata:",
      "      labels:",
      "        app: ${var.location_name}-inlets-client",
      "    spec:",
      "      containers:",
      "      - name: ${var.location_name}-inlets-client",
      "        image: ghcr.io/inlets/inlets-pro:0.9.14",
      "        imagePullPolicy: IfNotPresent",
      "        command: [\"inlets-pro\"]",
      "        args:",
      "        - \"uplink\"",
      "        - \"client\"",
      "        - \"--url=wss://${var.ingress_domain}/tunnels/${var.location_name}\"",
      "        - \"--token=${var.inlets_token}\"",
      "        - \"--upstream=6443=kubernetes.default.svc:443\"",
      "EOF"
    ]
  }
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
    inline = ["kubectl create namespace ${var.yugabyte_nodes_namespace}"]
  }
}

// Install Istio
resource "null_resource" "install_istio" {
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${var.istio_version} sh -",
      "istio-${var.istio_version}/bin/istioctl install --set profile=default -y"
    ]
  }
}

// Label istio namespace
resource "null_resource" "label_istio_namespace" {
  depends_on = [null_resource.install_istio]
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl label ns istio-system topology.istio.io/network=network2"
    ]
  }
}

// Apply IstioOperator configuration
resource "null_resource" "apply_istio_cluster_configuration" {
  depends_on = [null_resource.label_istio_namespace]
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_key.private_key
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF | istio-${var.istio_version}/bin/istioctl install -y -f -",
      "apiVersion: install.istio.io/v1alpha1",
      "kind: IstioOperator",
      "spec:",
      "  values:",
      "    global:",
      "      meshID: mesh1",
      "      multiCluster:",
      "        clusterName: cluster2",
      "      network: network2",
      "EOF"
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
      "istio-${var.istio_version}/samples/multicluster/gen-eastwest-gateway.sh --mesh mesh1 --cluster cluster2 --network network2 | istio-${var.istio_version}/bin/istioctl install -y -f -"
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
      "kubectl apply -n istio-system -f istio-${var.istio_version}/samples/multicluster/expose-services.yaml"
    ]
  }
}

// Create a secret to connect to the cluster
data "external" "cluster2_secret" {
  depends_on = [null_resource.apply_east_west_gateway]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(${local.ssh_command} istio-${var.istio_version}/bin/istioctl x create-remote-secret --name=cluster2)\" '{$content}'"
  ]
}





