locals {
  cm_prod_issuer = templatefile("${path.module}/templates/cert-manager/prod_issuer.yaml", { email_address : var.email_address })
}

// Get the kubeconfig
resource "null_resource" "set_gke_creds" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
  }
}

// Install cert manager
resource "null_resource" "install_cert_manager" {
  depends_on = [
    null_resource.set_gke_creds
  ]
  provisioner "local-exec" {
    command = <<-EOT
            kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/${var.cert_manager_version}/cert-manager.yaml && \
            
                kubectl -n cert-manager wait --for condition=Available --timeout=300s deploy/cert-manager-webhook && \
            cat <<-EOF | kubectl apply -f -
            ${local.cm_prod_issuer}
            EOF
        EOT
  }
}

