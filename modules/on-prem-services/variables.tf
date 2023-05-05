variable "ssh_key_path" {
  type        = string
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
variable "acm_namespace" {
  description = "The name of the ACM default namespace"
  type        = string
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
variable "istio_namespace" {
  description = "The root namespace for Istio"
  type        = string
}
variable "istio_ca_cert" {
  description = "The CA cert for Istio"
  type        = string
}
variable "istio_ca_key" {
  description = "The CA key for Istio"
  type        = string
}
variable "istio_root_cert" {
  description = "The root cert for Istio"
  type        = string
}
variable "istio_cert_chain" {
  description = "The cert chain for Istio"
  type        = string
}
variable "istio_mesh_name" {
  description = "The mesh name for Istio"
  type        = string
}
variable "istio_network_name" {
  description = "The network name for Istio"
  type        = string
}
variable "istio_cluster_name" {
  description = "The cluster name for Istio"
  type        = string
}

