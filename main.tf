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
  source                   = "github.com/btjimerson/anthos-baremetal-terraform"
  cluster_name             = format("pnap-%s", var.cluster_name)
  cloud                    = var.cloud
  pnap_client_id           = var.pnap_client_id
  pnap_client_secret       = var.pnap_client_secret
  pnap_location            = var.pnap_location
  pnap_worker_type         = var.pnap_worker_type
  pnap_cp_type             = var.pnap_cp_type
  gcp_project_id           = var.gcp_project_id
  worker_node_count        = var.pnap_worker_node_count
  ha_control_plane         = var.pnap_ha_control_plane
  load_balancer_ips        = var.pnap_load_balancer_ips
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
  depends_on               = [module.baremetal_anthos_cluster]
  source                   = "./modules/on-prem-services"
  ssh_key_path             = module.baremetal_anthos_cluster.ssh_key_path
  bastion_ip               = module.baremetal_anthos_cluster.bastion_host_ip
  username                 = module.baremetal_anthos_cluster.bastion_host_username
  location_name            = var.location_name
  yugabyte_nodes_namespace = var.yugabyte_nodes_namespace
  istio_version            = var.istio_version
  ssh_key = {
    private_key = module.baremetal_anthos_cluster.ssh_key.private_key
    public_key  = module.baremetal_anthos_cluster.ssh_key.public_key
  }
}

module "cloud_services" {
  depends_on                                   = [module.gke_cluster, module.on_prem_services, module.gke_auth]
  source                                       = "./modules/cloud-services"
  cluster_name                                 = format("gke-%s", var.cluster_name)
  cert_manager_version                         = var.cert_manager_version
  gcp_region                                   = var.gcp_region
  gcp_project_id                               = var.gcp_project_id
  acm_config_sync_source_format                = var.cloud_acm_config_sync_source_format
  acm_git_repo                                 = var.cloud_acm_git_repo
  acm_namespace                                = var.cloud_acm_namespace
  acm_repo_authentication                      = var.cloud_acm_repo_authentication
  acm_repo_branch                              = var.cloud_acm_repo_branch
  acm_repo_pat                                 = var.cloud_acm_repo_pat
  acm_repo_username                            = var.cloud_acm_repo_username
  gke_cluster_id                               = module.gke_cluster.cluster_id
  istio_version                                = var.istio_version
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


// Apply GKE cluster (cluster1) secret
resource "null_resource" "apply_cluster1_secret" {
  depends_on = [module.on_prem_services, module.cloud_services]
  connection {
    type        = "ssh"
    user        = module.baremetal_anthos_cluster.bastion_host_username
    private_key = module.baremetal_anthos_cluster.ssh_key.private_key
    host        = module.baremetal_anthos_cluster.bastion_host_ip
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f - ${module.cloud_services.cluster1_secret}"
    ]
  }
}

// Apply remote cluster (cluster2) secret
resource "null_resource" "apply_cluster2_secret" {
  depends_on = [module.on_prem_services, module.cloud_services]
  provisioner "local-exec" {
    command = "kubectl apply -f - ${module.on_prem_services.cluster2_secret}"
  }
}

# Kubeconfig
module "gke_auth" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  depends_on = [module.gke_cluster]

  project_id   = var.gcp_project_id
  location     = var.gcp_region
  cluster_name = format("gke-%s", var.cluster_name)
}




