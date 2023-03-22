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
  description = "The requested asn for Megaport"
  type        = string
  default     = "RAPID"
}

variable "gke_machine_type" {
  description = "The requested asn for Megaport"
  type        = string
  default     = "c2-standard-4"
}

variable "gcp_router_asn" {
  description = "The requested asn for Megaport"
  type        = number
  default     = 16550
}

variable "domain_name" {
  description = "The domain name to use for DNS records"
  type        = string
}

variable "cert_manager_version" {
  description = "The version of cert manager to install"
  type        = string
  default     = "v1.8.0"
}

variable "email_address" {
  description = "The email address to use with Cert Manager"
  type        = string
}

variable "pnap_network_name" {
  type        = string
  default     = ""
  description = "The network_id to use when creating server in PNAP"
}

variable "acm_namespace" {
  description = "The name of the ACM default namespace"
  type        = string
  default     = "config-management-system"
}

variable "acm_git_repo" {
  description = "The git repo URL for Anthos config management"
  type        = string
}

variable "acm_repo_branch" {
  description = "The repo branch to sync for ACM"
  type        = string
  default     = "main"
}

variable "acm_repo_authentication" {
  description = "The secret type for the ACM repo"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["ssh", "cookiefile", "gcenode", "gcpserviceaccount", "token", "none"], var.acm_repo_authentication)
    error_message = "Must be one of [ssh cookiefile gcenode gcpserviceaccount token none]"
  }

}

variable "acm_repo_username" {
  description = "The username to use for authentication to Git (only required if authentication is token)"
  type        = string
  default     = ""
}

variable "acm_repo_pat" {
  description = "The personal access token for authentication to Git (only required if authentication is token)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "acm_config_sync_source_format" {
  description = "The config sync source format (one of hierarchical | unstructured)"
  type        = string
  default     = "unstructured"
  validation {
    condition     = contains(["unstructured", "hierarchical"], var.acm_config_sync_source_format)
    error_message = "Must be on of [hierarchical unstructured]"
  }
}