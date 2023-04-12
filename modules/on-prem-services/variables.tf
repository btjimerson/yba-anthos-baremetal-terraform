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
variable "yugabyte_nodes_namespace" {
  type        = string
  description = "The namespace where Yugabyte nodes will be deployed"
}
variable "location_name" {
  type        = string
  description = "The name of the edge location"
}
variable "ssh_key" {
  type = object({
    public_key  = string
    private_key = string
  })
  description = "SSH Public and Private Key"
}
variable "istio_version" {
  description = "The version of Istio to install"
  type        = string
}
