variable "cluster_name" {
  description = "The name(s) of the clusters to be deployed"
  type        = string
}
variable "cert_manager_version" {
  description = "The version of cert manager to install"
  type        = string
}
variable "gcp_region" {
  description = "The GCP Region"
  type        = string
}
variable "gcp_project_id" {
  description = "The GCP Project ID"
  type        = string
}
variable "inlets_uplink_provider_namespace" {
  description = "The name of the namespace to install uplink provider"
  type        = string
}
variable "inlets_uplink_tunnels_namespace" {
  description = "The name of the namespace to install uplink tunnels"
  type        = string
}
variable "inlets_uplink_license" {
  description = "The license key for uplink"
  type        = string
}
variable "inlets_uplink_provider_domain" {
  description = "The domain to use for the provider"
  type        = string
}
variable "inlets_uplink_provider_email_address" {
  description = "The email address to use for the provider"
  type        = string
}
variable "inlets_uplink_tunnels_predefined_token_name" {
  description = "The name of the pre-defined token for tunnels"
  type        = string
}
variable "inlets_uplink_tunnels_predefined_token" {
  description = "The pre-defined token for tunnels"
  type        = string
}
variable "acm_namespace" {
  description = "The name of the ACM default namespace"
  type        = string
}
variable "acm_git_repo" {
  description = "The git repo URL for Anthos config management"
  type        = string
}
variable "acm_repo_branch" {
  description = "The repo branch to sync for ACM"
  type        = string
}
variable "acm_repo_authentication" {
  description = "The secret type for the ACM repo"
  type        = string
  validation {
    condition     = contains(["ssh", "cookiefile", "gcenode", "gcpserviceaccount", "token", "none"], var.acm_repo_authentication)
    error_message = "Must be one of [ssh cookiefile gcenode gcpserviceaccount token none]"
  }
}
variable "acm_repo_username" {
  description = "The username to use for authentication to Git (only required if authentication is token)"
  type        = string
}
variable "acm_repo_pat" {
  description = "The personal access token for authentication to Git (only required if authentication is token)"
  type        = string
  sensitive   = true
}
variable "acm_config_sync_source_format" {
  description = "The config sync source format (one of hierarchical | unstructured)"
  type        = string
  validation {
    condition     = contains(["unstructured", "hierarchical"], var.acm_config_sync_source_format)
    error_message = "Must be on of [hierarchical unstructured]"
  }
}
variable "gke_cluster_id" {
  description = "The id for the GKE cluster"
  type        = string
}
variable "istio_version" {
  description = "The version of Istio to install"
  type        = string
}
variable "yba_namespace" {
  description = "The name of the namespace for YBA"
  type        = string
}
variable "yba_kubeconfig" {
  description = "The kubeconfig for YBA"
  type        = string
}
variable "yba_pull_secret" {
  description = "The pull secret for YBA"
  type        = string
}
variable "yba_kubeconfig_config_map" {
  description = "The config map name for YBA kubeconfig"
  type        = string
}
variable "yba_version" {
  description = "The version of YBA to install"
  type        = string
}
variable "yba_sa" {
  description = "The name of the YBA service account"
  type        = string
}
variable "yba_role" {
  description = "The name of the YBA role"
  type        = string
}
variable "yba_role_binding" {
  description = "The name of the YBA role binding"
  type        = string
}
variable "yba_universe_management_namespace" {
  description = "The namespace for the universement management sa and role"
  type        = string
}
variable "yba_universe_management_sa" {
  description = "The name of the universe management service account"
  type        = string
}
variable "yba_universe_management_cluster_role" {
  description = "The name of the universe management cluster role"
  type        = string
}
variable "yba_universe_management_cluster_role_binding" {
  description = "The name of the universe management cluster role binding"
  type        = string
}
variable "yba_operator_namespace" {
  description = "The namespace for the YBA operator and related objects"
  type        = string
}
variable "yba_operator_github_repo" {
  description = "The URL of the YBA operator Github repo"
  type        = string
}
variable "yba_operator_service_account_manifest" {
  description = "The name of the YBA operator service account"
  type        = string
}
variable "yba_operator_cluster_role_manifest" {
  description = "The name of the YBA operator cluster role"
  type        = string
}
variable "yba_operator_cluster_role_binding_manifest" {
  description = "The name of the YBA operator cluster role binding"
  type        = string
}
variable "yba_operator_deployment_manifest" {
  description = "The name of the YBA operator deployment"
  type        = string
}
variable "yba_operator_admin_crd_manifest" {
  description = "The name of the admin user crd"
  type        = string
}
variable "yba_operator_cloud_provider_crd_manifest" {
  description = "The name of the cloud provider crd"
  type        = string
}
variable "yba_operator_universe_crd_manifest" {
  description = "The name of the universe crd"
  type        = string
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
