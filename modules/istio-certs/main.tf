// Create self-signed certs for Istio multicluster
resource "null_resource" "create_certs" {
  provisioner "local-exec" {
    command = <<-EOT
    pushd ${path.module}
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${var.istio_version} sh -
    mkdir -p certs
		cd certs
		make -f ../istio-${var.istio_version}/tools/certs/Makefile.selfsigned.mk root-ca
		make -f ../istio-${var.istio_version}/tools/certs/Makefile.selfsigned.mk ${var.istio_cloud_prefix}-cacerts
		make -f ../istio-${var.istio_version}/tools/certs/Makefile.selfsigned.mk ${var.istio_on_prem_prefix}-cacerts
    popd
    rm -rf ${path.module}/istio-${var.istio_version}
	  EOT
  }
}

// Read certs
data "external" "cloud_cluster_ca_cert" {
  depends_on = [null_resource.create_certs]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(cat ${path.module}/certs/${var.istio_cloud_prefix}/ca-cert.pem)\" '{$content}'"
  ]
}
data "external" "cloud_cluster_ca_key" {
  depends_on = [null_resource.create_certs]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(cat ${path.module}/certs/${var.istio_cloud_prefix}/ca-key.pem)\" '{$content}'"
  ]
}
data "external" "cloud_cluster_root_cert" {
  depends_on = [null_resource.create_certs]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(cat ${path.module}/certs/${var.istio_cloud_prefix}/root-cert.pem)\" '{$content}'"
  ]
}
data "external" "cloud_cluster_cert_chain" {
  depends_on = [null_resource.create_certs]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(cat ${path.module}/certs/${var.istio_cloud_prefix}/cert-chain.pem)\" '{$content}'"
  ]
}
data "external" "on_prem_cluster_ca_cert" {
  depends_on = [null_resource.create_certs]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(cat ${path.module}/certs/${var.istio_on_prem_prefix}/ca-cert.pem)\" '{$content}'"
  ]
}
data "external" "on_prem_cluster_ca_key" {
  depends_on = [null_resource.create_certs]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(cat ${path.module}/certs/${var.istio_on_prem_prefix}/ca-key.pem)\" '{$content}'"
  ]
}
data "external" "on_prem_cluster_root_cert" {
  depends_on = [null_resource.create_certs]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(cat ${path.module}/certs/${var.istio_on_prem_prefix}/root-cert.pem)\" '{$content}'"
  ]
}
data "external" "on_prem_cluster_cert_chain" {
  depends_on = [null_resource.create_certs]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(cat ${path.module}/certs/${var.istio_on_prem_prefix}/cert-chain.pem)\" '{$content}'"
  ]
}

