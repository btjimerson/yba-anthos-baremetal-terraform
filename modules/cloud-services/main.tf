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
  cm_prod_issuer = templatefile("${path.module}/templates/cert-manager/prod_issuer.yaml", {email_address: "bjimerson@gmail.com"})
  cm_staging_issuer = templatefile("${path.module}/templates/cert-manager/staging-issuer.yaml", {email_address: "bjimerson@gmail.com"})
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
    "jq -n --arg content \"$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')\" '{$content}'"
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

// Install Istio
resource "null_resource" "install_istio" {
  provisioner "local-exec" {
    command = "curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${var.istio_version} sh - && istio-${var.istio_version}/bin/istioctl install --set profile=default -y"
  }
}

// Label istio-system namespace
resource "null_resource" "label_istio_namespace" {
  depends_on = [null_resource.install_istio]
  provisioner "local-exec" {
    command = "kubectl label ns istio-system topology.istio.io/network=network1"
  }
}

// Apply IstioOperator configuration
resource "null_resource" "apply_istio_cluster_configuration" {
  depends_on = [null_resource.label_istio_namespace]
  provisioner "local-exec" {
    command = "istio-${var.istio_version}/bin/istioctl install -y -f ${path.module}/yaml/cluster1.yaml"
  }
}

// Apply east-west gateway
resource "null_resource" "apply_east_west_gateway" {
  depends_on = [null_resource.apply_istio_cluster_configuration]
  provisioner "local-exec" {
    command = "istio-${var.istio_version}/samples/multicluster/gen-eastwest-gateway.sh --mesh mesh1 --cluster cluster1 --network network1 | istio-${var.istio_version}/bin/istioctl install -y -f -"
  }
}

// Expose istio services
resource "null_resource" "expose_istio_services" {
  depends_on = [null_resource.apply_east_west_gateway]
  provisioner "local-exec" {
    command = "kubectl apply -n istio-system -f istio-${var.istio_version}/samples/multicluster/expose-services.yaml"
  }
}

// Create a secret to connect to the cluster
data "external" "cluster1_secret" {
  depends_on = [null_resource.apply_east_west_gateway]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(istio-${var.istio_version}/bin/istioctl x create-remote-secret --name=cluster1)\" '{$content}'"
  ]
}

// Remove istio installation
resource "null_resource" "remove_istio" {
  depends_on = [
    null_resource.install_istio,
    null_resource.label_istio_namespace,
    null_resource.apply_istio_cluster_configuration,
    null_resource.apply_east_west_gateway,
    null_resource.expose_istio_services
  ]
  provisioner "local-exec" {
    command = "rm -rf istio-${var.istio_version}"
  }
}

// Install and configure YBA
module "yba" {
  source                                       = "../yba"
  yba_admin_user_email                         = var.yba_admin_user_email
  yba_admin_user_environment                   = var.yba_admin_user_environment
  yba_admin_user_full_name                     = var.yba_admin_user_full_name
  yba_admin_user_kubernetes_name               = var.yba_admin_user_kubernetes_name
  yba_admin_user_password                      = var.yba_admin_user_password
  yba_kubeconfig                               = var.yba_kubeconfig
  yba_kubeconfig_config_map                    = var.yba_kubeconfig_config_map
  yba_namespace                                = var.yba_namespace
  yba_operator_admin_crd_manifest              = var.yba_operator_admin_crd_manifest
  yba_operator_cloud_provider_crd_manifest     = var.yba_operator_cloud_provider_crd_manifest
  yba_operator_cluster_role_binding_manifest   = var.yba_operator_cluster_role_binding_manifest
  yba_operator_cluster_role_manifest           = var.yba_operator_cluster_role_manifest
  yba_operator_deployment_manifest             = var.yba_operator_deployment_manifest
  yba_operator_service_account_manifest        = var.yba_operator_service_account_manifest
  yba_operator_github_repo                     = var.yba_operator_github_repo
  yba_operator_namespace                       = var.yba_operator_namespace
  yba_operator_universe_crd_manifest           = var.yba_operator_universe_crd_manifest
  yba_pull_secret                              = var.yba_pull_secret
  yba_role                                     = var.yba_role
  yba_role_binding                             = var.yba_role_binding
  yba_sa                                       = var.yba_sa
  yba_universe_management_cluster_role         = var.yba_universe_management_cluster_role
  yba_universe_management_cluster_role_binding = var.yba_universe_management_cluster_role_binding
  yba_universe_management_namespace            = var.yba_universe_management_namespace
  yba_universe_management_sa                   = var.yba_universe_management_sa
  yba_version                                  = var.yba_version
}

# GKE hub membership for Anthos config management
resource "google_gke_hub_membership" "cloud_membership" {
  depends_on    = [module.yba]
  membership_id = "${var.cluster_name}-membership"
  provider      = google-beta
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${var.gke_cluster_id}"
    }
  }
}

# Anthos config managmement
resource "google_gke_hub_feature_membership" "cloud_feature_member" {
  depends_on = [google_gke_hub_membership.cloud_membership]
  location   = "global"
  membership = google_gke_hub_membership.cloud_membership.membership_id
  feature    = "configmanagement"
  provider   = google-beta
  configmanagement {
    config_sync {
      source_format = var.acm_config_sync_source_format
      git {
        sync_repo   = var.acm_git_repo
        sync_branch = var.acm_repo_branch
        secret_type = var.acm_repo_authentication
      }
    }
  }
}

# Wait for a little bit to let ACM create it's namespace
# before we put the github credentials in there
resource "time_sleep" "cloud_wait_for_namespace" {
  depends_on      = [google_gke_hub_feature_membership.cloud_feature_member]
  create_duration = "60s"
}

# Credentials for Github sync
resource "kubernetes_secret" "git_creds" {
  depends_on = [time_sleep.cloud_wait_for_namespace]
  metadata {
    name      = "git-creds"
    namespace = var.acm_namespace
  }

  data = {
    username = var.acm_repo_username
    token    = var.acm_repo_pat
  }
}

