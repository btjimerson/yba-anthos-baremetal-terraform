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