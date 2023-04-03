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
  ssh_command = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${var.ssh_key_path} ${var.username}@${var.bastion_ip}"
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

data "external" "nginx_ingress_ip" {
  depends_on = [helm_release.nginx_ingress]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(${local.ssh_command}) kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'\" '{$content}'"
  ]
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