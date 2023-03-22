<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name(s) of the clusters to be deployed | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name to use for DNS records | `string` | n/a | yes |
| <a name="input_email_address"></a> [email\_address](#input\_email\_address) | The email address to use with Cert Manager | `string` | n/a | yes |
| <a name="input_cert_manager_version"></a> [cert\_manager\_version](#input\_cert\_manager\_version) | The version of cert manager to install | `string` | n/a | yes |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | The GCP Region | `string` | n/a | yes |
| <a name="input_gcp_project_id"></a> [gcp\_project\_id](#input\_gcp\_project\_id) | The GCP Project ID | `string` | n/a | yes |
| <a name="input_redis_load_balancer_ip"></a> [redis\_load\_balancer\_ip](#input\_redis\_load\_balancer\_ip) | The IP Address of the Redis Load Balancer IP | `string` | n/a | yes |
<!-- END_TF_DOCS -->