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

resource "null_resource" "deploy_redis" {
  depends_on = [
    null_resource.install_helm
  ]
  connection {
    type        = "ssh"
    user        = var.username
    private_key = file(var.ssh_key_path)
    host        = var.bastion_ip
  }

  provisioner "remote-exec" {
    inline = [
      "helm install redis bitnami/redis --create-namespace --namespace redis --set rbac.create=true --set master.service.loadBalancerIP=${var.redis_load_balancer_ip} --set master.service.type=LoadBalancer --set auth.enabled=false --set global.storageClass=local-shared"
    ]
  }
}