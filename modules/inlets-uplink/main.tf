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

// Namespace for inlets uplink provider
resource "kubernetes_namespace" "inlets_uplink_provider_namespace" {
  metadata {
    name = var.inlets_uplink_provider_namespace
  }
}

// License key for inlets uplink
resource "kubernetes_secret" "inlets_uplink_license" {
  metadata {
    name      = "inlets-uplink-license"
    namespace = var.inlets_uplink_provider_namespace
  }
  data = {
    license = var.inlets_uplink_license
  }
}

// nginx ingress controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"
}

//The next 2 stanzas are a hack to get the ingress controller ip for output
// nginx ingress controll ip from kubectl
resource "null_resource" "nginx_ingress_ip" {
  depends_on = [helm_release.nginx_ingress]
  provisioner "local-exec" {
    command = "kubectl get svc nginx-ingress-controller -o jsonpath=\"{.status.loadBalancer.ingress[0].ip}\" > ${path.module}/nginx-ingress-ip.txt"
  }
}

// Write nginx ingress controller ip to file
data "local_file" "nginx_ingress_ip" {
  depends_on = [null_resource.nginx_ingress_ip]
  filename   = "${path.module}/nginx-ingress-ip.txt"
}
//End hack

// Inlets uplink helm release
resource "helm_release" "inlets_uplink" {
  name      = "inlets-uplink"
  namespace = var.inlets_uplink_provider_namespace
  chart     = "oci://ghcr.io/openfaasltd/inlets-uplink-provider"
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
}
