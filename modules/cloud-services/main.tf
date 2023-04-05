terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  cm_prod_issuer    = templatefile("${path.module}/templates/cert-manager/prod_issuer.yaml", { 
    email_address : var.inlets_uplink_provider_email_address,
    namespace: var.inlets_uplink_provider_namespace
  })
  cm_staging_issuer = templatefile("${path.module}/templates/cert-manager/staging-issuer.yaml", {
    email_address : var.inlets_uplink_provider_email_address,
    namespace: var.inlets_uplink_provider_namespace
  })
}

// Get the kubeconfig
resource "null_resource" "set_gke_creds" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
  }
}

// nginx ingress controller
resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  set {
    name  = "rbac.create"
    value = true
  }
}

// Ingress controller IP
data "external" "nginx_ingress_ip" {
  depends_on = [helm_release.nginx_ingress]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'\" '{$content}'"
  ]
}

// Install cert manager
resource "null_resource" "install_cert_manager" {
  depends_on = [
    null_resource.set_gke_creds,
    helm_release.nginx_ingress
  ]
  provisioner "local-exec" {
    command = <<-EOT
            kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/${var.cert_manager_version}/cert-manager.yaml && \
            kubectl -n cert-manager wait --for condition=Available --timeout=300s deploy/cert-manager-webhook && \
            cat <<-EOF | kubectl apply -f -
            ${local.cm_staging_issuer}
            EOF
        EOT
  }
}

// Namespace for inlets uplink provider
resource "kubernetes_namespace" "inlets_uplink_provider_namespace" {
  metadata {
    name = var.inlets_uplink_provider_namespace
  }
}

// License key for inlets uplink
resource "kubernetes_secret" "inlets_uplink_license" {
  depends_on = [kubernetes_namespace.inlets_uplink_provider_namespace]
  metadata {
    name      = "inlets-uplink-license"
    namespace = var.inlets_uplink_provider_namespace
  }
  data = {
    license = var.inlets_uplink_license
  }
}

// Inlets uplink helm release
resource "helm_release" "inlets_uplink" {
  depends_on = [kubernetes_namespace.inlets_uplink_provider_namespace]
  name       = "inlets-uplink"
  namespace  = var.inlets_uplink_provider_namespace
  chart      = "oci://ghcr.io/openfaasltd/inlets-uplink-provider"
  set {
    name  = "clientRouter.domain"
    value = var.inlets_uplink_provider_domain
  }
  set {
    name  = "clientRouter.tls.issuer.email"
    value = var.inlets_uplink_provider_email_address
  }
  set {
    name  = "clientRouter.tls.ingress.enabled"
    value = true
  }
  set {
    name  = "clientRouter.tls.ingress.class"
    value = "nginx"
  }
  set {
    name  = "clientRouter.tls.issuerName"
    value = "letsencrypt-staging"
  }
  set {
    name = "clientRouter.tls.issuer.enabled"
    value = false
  }
}

// Namespace for customer tunnels
resource "kubernetes_namespace" "inlets_uplink_tunnels_namespace" {
  metadata {
    name = var.inlets_uplink_tunnels_namespace
  }
}

// License secret for tunnels
resource "kubernetes_secret" "inlets_uplink_tunnels_license_secret" {
  depends_on = [kubernetes_namespace.inlets_uplink_tunnels_namespace]
  metadata {
    name      = "inlets-uplink-license"
    namespace = var.inlets_uplink_tunnels_namespace
  }
  data = {
    license = var.inlets_uplink_license
  }
}

//Pre-defined token secret for tunnels
resource "kubernetes_secret" "inlets_uplink_tunnels_predefined_token_secret" {
  depends_on = [kubernetes_namespace.inlets_uplink_tunnels_namespace]
  metadata {
    name      = var.inlets_uplink_tunnels_predefined_token_name
    namespace = var.inlets_uplink_tunnels_namespace
  }
  data = {
    token = var.inlets_uplink_tunnels_predefined_token
  }
}

