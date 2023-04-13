variable "istio_version" {
  description = "The version of Istio to use"
  type        = string
}
variable "istio_cloud_prefix" {
  description = "The name of the cloud prefix in Istio"
  type        = string
}
variable "istio_on_prem_prefix" {
  description = "The name of the on-prem cluster in Istio"
  type        = string
}