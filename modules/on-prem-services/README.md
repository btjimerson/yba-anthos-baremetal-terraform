<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ssh_key_path"></a> [ssh\_key\_path](#input\_ssh\_key\_path) | SSH Public and Private Key | `any` | n/a | yes |
| <a name="input_bastion_ip"></a> [bastion\_ip](#input\_bastion\_ip) | The bastion host/admin workstation public IP Address | `string` | n/a | yes |
| <a name="input_username"></a> [username](#input\_username) | The username used to ssh to hosts | `string` | n/a | yes |
| <a name="input_redis_load_balancer_ip"></a> [redis\_load\_balancer\_ip](#input\_redis\_load\_balancer\_ip) | The IP Address of the Redis Load Balancer IP | `string` | n/a | yes |
<!-- END_TF_DOCS -->