locals {
  ssh_command = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${var.ssh_key_path} ${var.username}@${var.bastion_ip}"
  unix_home   = var.username == "root" ? "/root" : "/home/${var.username}"
}

resource "null_resource" "install_helm" {
  connection {
    type        = "ssh"
    user        = var.username
    private_key = file(var.ssh_key_path)
    host        = var.bastion_ip
  }
  provisioner "remote-exec" {
    inline = [
      "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",
      "helm repo add bitnami https://charts.bitnami.com/bitnami",
      "helm repo update"
    ]

  }
}

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
      "        - \"--upstream=6443:kubernetes.default.svc:443\"",
      "EOF",
      "kubectl -n kube-system get secret remote-admin-token -o jsonpath='{.data.token}' | base64 --decode >> remote-admin-token.txt"
    ]
  }
}

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

