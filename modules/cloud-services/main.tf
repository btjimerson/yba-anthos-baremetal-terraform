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

// Get the kubeconfig
resource "null_resource" "set_gke_creds" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
  }
}

// Download Istio
resource "null_resource" "download_istio" {
  provisioner "local-exec" {
    command = "curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${var.istio_version} sh -"
  }
}

// Create istio root namespace
resource "kubernetes_namespace" "istio_namespace" {
  metadata {
    name = var.istio_namespace
    labels = {
      "topology.istio.io/network" = var.istio_network_name
    }
  }
}

//Install certs secret
resource "null_resource" "istio_certs_secret" {
  depends_on = [
    null_resource.set_gke_creds,
    kubernetes_namespace.istio_namespace
  ]
  provisioner "local-exec" {
    command = <<-EOT
      kubectl create secret generic cacerts -n ${var.istio_namespace} \
        --from-literal=ca-cert.pem='${var.istio_ca_cert}' \
        --from-literal=ca-key.pem='${var.istio_ca_key}' \
        --from-literal=root-cert.pem='${var.istio_root_cert}' \
        --from-literal=cert-chain.pem='${var.istio_cert_chain}'
      EOT
  }
}

// Apply IstioOperator configuration
resource "null_resource" "apply_istio_cluster_configuration" {
  depends_on = [
    null_resource.set_gke_creds,
    null_resource.download_istio,
    null_resource.istio_certs_secret
  ]
  provisioner "local-exec" {
    command = <<-EOT
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
  }
}

// Apply east-west gateway
resource "null_resource" "apply_east_west_gateway" {
  depends_on = [
    null_resource.set_gke_creds,
    null_resource.apply_istio_cluster_configuration
  ]
  provisioner "local-exec" {
    command = <<-EOT
      istio-${var.istio_version}/samples/multicluster/gen-eastwest-gateway.sh \
        --mesh ${var.istio_mesh_name} \
        --cluster ${var.istio_cluster_name} \
        --network ${var.istio_network_name} | \
        istio-${var.istio_version}/bin/istioctl install -y -f -
    EOT
  }
}

// Expose istio services
resource "null_resource" "expose_istio_services" {
  depends_on = [
    null_resource.set_gke_creds,
    null_resource.apply_east_west_gateway
  ]
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -n istio-system -f istio-${var.istio_version}/samples/multicluster/expose-services.yaml
    EOT
  }
}

// Create a secret to connect to the cluster
data "external" "cluster_secret" {
  depends_on = [
    null_resource.set_gke_creds,
    null_resource.apply_east_west_gateway
  ]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(istio-${var.istio_version}/bin/istioctl x create-remote-secret --name=${var.istio_cluster_name})\" '{$content}'"
  ]
}

// Remove istio
resource "null_resource" "remove_istio" {
  depends_on = [
    null_resource.download_istio,
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
  depends_on = [
    null_resource.apply_istio_cluster_configuration,
    data.external.cluster_secret
  ]
  source                                       = "../yba"
  yba_kubeconfig                               = var.yba_kubeconfig
  yba_kubeconfig_config_map                    = var.yba_kubeconfig_config_map
  yba_namespace                                = var.yba_namespace
  yba_operator_admin_crd_manifest              = var.yba_operator_admin_crd_manifest
  yba_operator_cloud_provider_crd_manifest     = var.yba_operator_cloud_provider_crd_manifest
  yba_operator_cluster_role_binding_manifest   = var.yba_operator_cluster_role_binding_manifest
  yba_operator_cluster_role_manifest           = var.yba_operator_cluster_role_manifest
  yba_operator_deployment_manifest             = var.yba_operator_deployment_manifest
  yba_operator_service_account_manifest        = var.yba_operator_service_account_manifest
  yba_operator_software_crd_manifest           = var.yba_operator_software_crd_manifest
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

# Wait for a little bit to let ACM create its namespace
# before we put the github credentials in there
resource "time_sleep" "cloud_wait_for_namespace" {
  depends_on      = [google_gke_hub_feature_membership.cloud_feature_member]
  create_duration = "120s"
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

