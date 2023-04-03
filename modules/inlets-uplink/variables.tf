variable "ssh_key_path" {
  description = "SSH Public and Private Key"
}

variable "bastion_ip" {
  type        = string
  description = "The bastion host/admin workstation public IP Address"
}

variable "username" {
  type        = string
  description = "The username used to ssh to hosts"
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