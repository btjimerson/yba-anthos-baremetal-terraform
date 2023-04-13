variable "cluster_name" {
  description = "The name(s) of the clusters to be deployed"
  type        = string
  default     = "my-cluster"
}
variable "cloud" {
  description = "The Cloud to deploy the Baremetal cluster on"
  type        = string
  default     = "PNAP"
}
variable "pnap_client_id" {
  description = "The client id for authentication to pnap"
  type        = string
}
variable "pnap_client_secret" {
  description = "The client secret for authentication to pnap"
  type        = string
}
variable "pnap_location" {
  description = "The pnap region to deploy nodes to"
  type        = string
  default     = "PHX"
}
variable "pnap_worker_type" {
  description = "The type of PNAP server to deploy for worker nodes"
  type        = string
  default     = "s2.c1.medium"
}
variable "pnap_worker_node_count" {
  description = "The number of worker nodes in PNAP"
  type        = number
  default     = 1
}
variable "pnap_cp_type" {
  description = "The type of PNAP server to deploy for control plane nodes"
  type        = string
  default     = "s2.c1.medium"
}
variable "pnap_ha_control_plane" {
  description = "Do you want a highly available control plane?"
  type        = bool
  default     = true
}
variable "gcp_project_id" {
  description = "The GCP Project ID"
  type        = string
}
variable "gcp_region" {
  description = "The GCP Region"
  type        = string
  default     = "us-west4"
}
variable "gke_node_count" {
  description = "The number of worker nodes for the GKE cluster"
  type        = number
  default     = 1
}
variable "gke_release_channel" {
  description = "The release channel for GKE"
  type        = string
  default     = "RAPID"
}
variable "gke_machine_type" {
  description = "The machine type for GKE nodes"
  type        = string
  default     = "c2-standard-4"
}
variable "gcp_router_asn" {
  description = "The requested asn for Megaport"
  type        = number
  default     = 16550
}
variable "cloud_acm_namespace" {
  description = "The name of the ACM for GKE default namespace"
  type        = string
  default     = "config-management-system"
}
variable "cloud_acm_git_repo" {
  description = "The git repo URL for ACM for GKE"
  type        = string
}
variable "cloud_acm_repo_branch" {
  description = "The repo branch to sync for ACM for GKE"
  type        = string
  default     = "main"
}
variable "cloud_acm_repo_authentication" {
  description = "The secret type for the ACM for GKE repo"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["ssh", "cookiefile", "gcenode", "gcpserviceaccount", "token", "none"], var.cloud_acm_repo_authentication)
    error_message = "Must be one of [ssh cookiefile gcenode gcpserviceaccount token none]"
  }
}
variable "cloud_acm_repo_username" {
  description = "The username to use for authentication to Git (only required if authentication is token)"
  type        = string
  default     = ""
}
variable "cloud_acm_repo_pat" {
  description = "The personal access token for authentication to Git (only required if authentication is token)"
  type        = string
  default     = ""
  sensitive   = true
}
variable "cloud_acm_config_sync_source_format" {
  description = "The config sync source format (one of hierarchical | unstructured)"
  type        = string
  default     = "unstructured"
  validation {
    condition     = contains(["unstructured", "hierarchical"], var.cloud_acm_config_sync_source_format)
    error_message = "Must be on of [hierarchical unstructured]"
  }
}
variable "yba_namespace" {
  description = "The name of the namespace for YBA"
  type        = string
  default     = "yugabyte"
}
variable "yba_pull_secret" {
  description = "The pull secret for YBA"
  type        = string
}
variable "yba_kubeconfig_config_map" {
  description = "The config map name for YBA kubeconfig"
  type        = string
  default     = "yugabyte-kubeconfig-config"
}
variable "yba_version" {
  description = "The version of YBA to install"
  type        = string
}
variable "yba_sa" {
  description = "The name of the YBA service account"
  type        = string
  default     = "yba-sa"
}
variable "yba_role" {
  description = "The name of the YBA role"
  type        = string
  default     = "yba-role"
}
variable "yba_role_binding" {
  description = "The name of the YBA role binding"
  type        = string
  default     = "yba-role-binding"
}
variable "yba_universe_management_namespace" {
  description = "The namespace for the universement management sa and role"
  type        = string
  default     = "kube-system"
}
variable "yba_universe_management_sa" {
  description = "The name of the universe management service account"
  type        = string
  default     = "yugabyte-platform-universe-management"
}
variable "yba_universe_management_cluster_role" {
  description = "The name of the universe management cluster role"
  type        = string
  default     = "yugabyte-platform-global-admin"
}
variable "yba_universe_management_cluster_role_binding" {
  description = "The name of the universe management cluster role binding"
  type        = string
  default     = "yugabyte-platform-global-admin"
}
variable "yba_operator_namespace" {
  description = "The namespace for the YBA operator and related objects"
  type        = string
  default     = "yba-operator"
}
variable "yba_operator_github_repo" {
  description = "The URL of the YBA operator Github repo"
  type        = string
}
variable "yba_operator_service_account_manifest" {
  description = "The name of the YBA operator service account"
  type        = string
  default     = "operator-sa.yaml"
}
variable "yba_operator_cluster_role_manifest" {
  description = "The name of the YBA operator cluster role"
  type        = string
  default     = "operator-cluster-role.yaml"
}
variable "yba_operator_cluster_role_binding_manifest" {
  description = "The name of the YBA operator cluster role binding"
  type        = string
  default     = "operator-cluster-role-binding.yaml"
}
variable "yba_operator_deployment_manifest" {
  description = "The name of the YBA operator deployment"
  type        = string
  default     = "operator-deployment.yaml"
}
variable "yba_operator_admin_crd_manifest" {
  description = "The name of the admin user crd"
  type        = string
  default     = "adminusers-crd.yaml"
}
variable "yba_operator_cloud_provider_crd_manifest" {
  description = "The name of the cloud provider crd"
  type        = string
  default     = "cloudproviders-crd.yaml"
}
variable "yba_operator_universe_crd_manifest" {
  description = "The name of the universe crd"
  type        = string
  default     = "universes-crd.yaml"
}
variable "yba_admin_user_kubernetes_name" {
  description = "The Kubernetes name for the YBA admin user"
  type        = string
}
variable "yba_admin_user_full_name" {
  description = "The full name for the YBA admin user"
  type        = string
}
variable "yba_admin_user_password" {
  description = "The password for the YBA admin user"
  type        = string
}
variable "yba_admin_user_email" {
  description = "The email address for the YBA admin user"
  type        = string
}
variable "yba_admin_user_environment" {
  description = "The environment for the YBA admin user"
  type        = string
}
variable "yugabyte_nodes_namespace" {
  type        = string
  default     = "yb-nodes"
  description = "The namespace where Yugabyte nodes will be deployed"
}
variable "istio_version" {
  description = "The version of Istio to install"
  type        = string
}
variable "istio_namespace" {
  description = "The root namespace for Istio"
  type        = string
  default     = "istio-system"
}
variable "istio_mesh_name" {
  description = "The name of the Istio mesh"
  type        = string
  default     = "mesh1"
}
variable "istio_cloud_prefix" {
  description = "The prefix for Istio objects in GKE"
  type        = string
  default     = "cloud"
}
variable "istio_on_prem_prefix" {
  description = "The prefix for Istio objects in on-prem"
  type        = string
}
