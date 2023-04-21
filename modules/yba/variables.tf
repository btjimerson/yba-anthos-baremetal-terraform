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
variable "yba_operator_software_crd_manifest" {
  description = "The name of the software crd"
  type        = string
}
