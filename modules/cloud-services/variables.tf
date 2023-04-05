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

