terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~>1.14.0"
    }
  }
}

data "google_client_config" "default" {}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "kubernetes" {
  host                   = "https://${module.gke_cluster.endpoint}"
  cluster_ca_certificate = base64decode(module.gke_cluster.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke_cluster.endpoint}"
    cluster_ca_certificate = base64decode(module.gke_cluster.cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

provider "kubectl" {
  host                   = "https://${module.gke_cluster.endpoint}"
  cluster_ca_certificate = base64decode(module.gke_cluster.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

module "baremetal_anthos_cluster" {
  source             = "github.com/btjimerson/anthos-baremetal-terraform"
  cluster_name       = format("pnap-%s", var.cluster_name)
  cloud              = var.cloud
  pnap_client_id     = var.pnap_client_id
  pnap_client_secret = var.pnap_client_secret
  pnap_location      = var.pnap_location
  pnap_worker_type   = var.pnap_worker_type
  pnap_cp_type       = var.pnap_cp_type
  pnap_network_name  = var.pnap_network_name
  gcp_project_id     = var.gcp_project_id
  worker_node_count  = var.pnap_worker_node_count
  ha_control_plane   = var.pnap_ha_control_plane
}

locals {
  redis_load_balancer_ip = cidrhost(module.baremetal_anthos_cluster.private_subnet, -4)
}

module "gcp_networking" {
  source         = "./modules/gcp-networking"
  cluster_name   = var.cluster_name
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
}

module "gke_cluster" {
  source              = "./modules/gke-cluster"
  cluster_name        = format("gke-%s", var.cluster_name)
  gcp_project_id      = var.gcp_project_id
  gcp_region          = var.gcp_region
  gke_node_count      = var.gke_node_count
  gke_release_channel = var.gke_release_channel
  gke_machine_type    = var.gke_machine_type
  gcp_network_name    = module.gcp_networking.gcp_network_name
  gcp_subnet_name     = module.gcp_networking.gcp_subnet_name
}

module "on_prem_services" {
  depends_on             = [module.baremetal_anthos_cluster]
  source                 = "./modules/on-prem-services"
  ssh_key_path           = module.baremetal_anthos_cluster.ssh_key_path
  bastion_ip             = module.baremetal_anthos_cluster.bastion_host_ip
  username               = module.baremetal_anthos_cluster.bastion_host_username
  redis_load_balancer_ip = local.redis_load_balancer_ip
}

module "cloud_services" {
  depends_on             = [module.gke_cluster, module.on_prem_services]
  source                 = "./modules/cloud-services"
  cluster_name           = format("gke-%s", var.cluster_name)
  domain_name            = var.domain_name
  email_address          = var.email_address
  cert_manager_version   = var.cert_manager_version
  gcp_region             = var.gcp_region
  gcp_project_id         = var.gcp_project_id
  redis_load_balancer_ip = local.redis_load_balancer_ip
}

# Kubeconfig
module "gke_auth" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  depends_on = [module.gke_cluster]

  project_id   = var.gcp_project_id
  location     = var.gcp_region
  cluster_name = format("gke-%s", var.cluster_name)
}

#Inlets uplink server
module "inlets_uplink" {
  depends_on                                  = [module.cloud_services]
  source                                      = "./modules/inlets-uplink"
  inlets_uplink_provider_namespace            = var.inlets_uplink_provider_namespace
  inlets_uplink_tunnels_namespace             = var.inlets_uplink_tunnels_namespace
  inlets_uplink_license                       = var.inlets_uplink_license
  inlets_uplink_provider_domain               = var.inlets_uplink_provider_domain
  inlets_uplink_provider_email_address        = var.inlets_uplink_provider_email_address
  inlets_uplink_tunnels_predefined_token      = var.inlets_uplink_tunnels_predefined_token
  inlets_uplink_tunnels_predefined_token_name = var.inlets_uplink_tunnels_predefined_token_name
}

# YugabyteDB Anywhere
module "yba" {
  depends_on = [
    module.cloud_services,
    module.gke_auth
  ]
  source                                       = "./modules/yba"
  yba_admin_user_email                         = var.yba_admin_user_email
  yba_admin_user_environment                   = var.yba_admin_user_environment
  yba_admin_user_full_name                     = var.yba_admin_user_full_name
  yba_admin_user_kubernetes_name               = var.yba_admin_user_kubernetes_name
  yba_admin_user_password                      = var.yba_admin_user_password
  yba_kubeconfig                               = module.gke_auth.kubeconfig_raw
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
resource "google_gke_hub_membership" "membership" {
  membership_id = "${var.cluster_name}-membership"
  provider      = google-beta
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke_cluster.cluster_id}"
    }
  }
}

# Anthos config managmement
resource "google_gke_hub_feature_membership" "feature_member" {
  depends_on = [module.inlets_uplink]
  location   = "global"
  membership = google_gke_hub_membership.membership.membership_id
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
resource "time_sleep" "wait_for_namespace" {
  depends_on      = [google_gke_hub_feature_membership.feature_member]
  create_duration = "60s"
}

# Credentials for Github sync
resource "kubernetes_secret" "git_creds" {
  depends_on = [time_sleep.wait_for_namespace]
  metadata {
    name      = "git-creds"
    namespace = var.acm_namespace
  }

  data = {
    username = var.acm_repo_username
    token    = var.acm_repo_pat
  }
}

