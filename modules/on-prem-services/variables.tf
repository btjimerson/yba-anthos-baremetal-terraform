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

variable "redis_load_balancer_ip" {
  description = "The IP Address of the Redis Load Balancer IP"
  type        = string
}
