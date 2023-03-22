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

# Credentials for Github sync
resource "kubernetes_secret" "git_creds" {
  depends_on = [google_gke_hub_feature_membership.feature_member]
  metadata {
    name      = "git-creds"
    namespace = var.acm_namespace
  }

  data = {
    username = var.acm_repo_username
    token    = var.acm_repo_pat
  }
}
