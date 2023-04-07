terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~>1.14.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.2.1"
    }
  }
}

// Fetch the remote manifests
data "http" "yba_operator_admin_user_crd_yaml" {
  url = "${var.yba_operator_github_repo}/${var.yba_operator_admin_crd_manifest}"
}
data "http" "yba_operator_cloud_provider_crd_yaml" {
  url = "${var.yba_operator_github_repo}/${var.yba_operator_cloud_provider_crd_manifest}"
}
data "http" "yba_operator_universe_crd_yaml" {
  url = "${var.yba_operator_github_repo}/${var.yba_operator_universe_crd_manifest}"
}
data "http" "yba_operator_service_account_yaml" {
  url = "${var.yba_operator_github_repo}/${var.yba_operator_service_account_manifest}"
}
data "http" "yba_operator_cluster_role_yaml" {
  url = "${var.yba_operator_github_repo}/${var.yba_operator_cluster_role_manifest}"
}
data "http" "yba_operator_cluster_role_binding_yaml" {
  url = "${var.yba_operator_github_repo}/${var.yba_operator_cluster_role_binding_manifest}"
}
data "http" "yba_operator_deployment_yaml" {
  url = "${var.yba_operator_github_repo}/${var.yba_operator_deployment_manifest}"
}

// Namespace for YBA
resource "kubernetes_namespace" "yba_namespace" {
  metadata {
    name = var.yba_namespace
  }
}

// Pull secret for YBA
resource "kubernetes_secret" "yugabyte_pull_secret" {
  depends_on = [kubernetes_namespace.yba_namespace]
  metadata {
    name      = "yugabyte-k8s-pull-secret"
    namespace = var.yba_namespace
  }
  data = {
    ".dockerconfigjson" = var.yba_pull_secret
  }
  type = "kubernetes.io/dockerconfigjson"
}

// Config map for YBA pull secret
resource "kubernetes_config_map" "yba_pull_secret_config_map" {
  depends_on = [kubernetes_namespace.yba_namespace]
  metadata {
    name      = "yugabyte-pull-secret-config-map"
    namespace = var.yba_namespace
  }
  data = {
    "yugabyte-pull-secret.yaml" = <<EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: yugabyte-pull-secret-config-map
  namespace: ${var.yba_namespace}
data:
  yugabyte-pull-secret.yaml: |
    apiVersion: v1
    kind: Secret
    metadata:
      name: yugabyte-k8s-pull-secret
    data:
      .dockerconfigjson: ${base64encode(var.yba_pull_secret)}
    type: kubernetes.io/dockerconfigjson
EOT
  }
}

// Install YBA helm chart
resource "helm_release" "yba" {
  depends_on = [
    kubernetes_namespace.yba_namespace,
    kubernetes_secret.yugabyte_pull_secret
  ]
  name       = "yugaware"
  namespace  = var.yba_namespace
  version    = var.yba_version
  repository = "https://charts.yugabyte.com"
  chart      = "yugaware"
}

// Get the IP address for YBA
data "external" "yba_ui_ip" {
  depends_on = [helm_release.yba]
  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(kubectl get svc yugaware-yugaware-ui -n ${var.yba_namespace} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')\" '{$content}'"
  ]
}

// Create the YBA service account
resource "kubernetes_service_account" "yba_sa" {
  depends_on = [kubernetes_namespace.yba_namespace]
  metadata {
    name      = var.yba_sa
    namespace = var.yba_namespace
  }
}

// Create the YBA role
resource "kubernetes_role" "yba_role" {
  depends_on = [kubernetes_namespace.yba_namespace]
  metadata {
    name      = var.yba_role
    namespace = var.yba_namespace
  }
  rule {
    api_groups = [
      "",
      "apps",
      "autoscaling",
      "batch",
      "extensions",
      "policy",
      "rbac.authorization.k8s.io"
    ]
    resources = [
      "pods",
      "componentstatuses",
      "configmaps",
      "daemonsets",
      "deployments",
      "events",
      "endpoints",
      "horizontalpodautoscalers",
      "ingress",
      "jobs",
      "limitranges",
      "namespaces",
      "nodes",
      "pods",
      "persistentvolumes",
      "persistentvolumeclaims",
      "resourcequotas",
      "replicasets",
      "replicationcontrollers",
      "secrets",
      "serviceaccounts",
      "services"
    ]
    verbs = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

// Create the YBA role binding
resource "kubernetes_role_binding" "yba_role_binding" {
  depends_on = [
    kubernetes_namespace.yba_namespace,
    kubernetes_role.yba_role,
    kubernetes_service_account.yba_sa
  ]
  metadata {
    name      = var.yba_role_binding
    namespace = var.yba_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = var.yba_role
  }
  subject {
    namespace = var.yba_namespace
    kind      = "ServiceAccount"
    name      = var.yba_sa
  }

}

// Create the universe management service account
resource "kubernetes_service_account" "universe_management_sa" {
  metadata {
    name      = var.yba_universe_management_sa
    namespace = var.yba_universe_management_namespace
  }
}

// Create the universe management cluster role
resource "kubernetes_cluster_role" "universe_management_cluster_role" {
  metadata {
    name = var.yba_universe_management_cluster_role
  }
  rule {
    api_groups = [""]
    resources = [
      "nodes",
      "nodes/proxy",
      "services",
      "endpoints",
      "pods"
    ]
    verbs = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
}

// Create the universe management role binding
resource "kubernetes_cluster_role_binding" "universe_management_cluster_role_binding" {
  depends_on = [
    kubernetes_service_account.universe_management_sa,
    kubernetes_cluster_role.universe_management_cluster_role
  ]
  metadata {
    name = var.yba_universe_management_cluster_role_binding
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = var.yba_universe_management_cluster_role
  }
  subject {
    namespace = var.yba_universe_management_namespace
    kind      = "ServiceAccount"
    name      = var.yba_universe_management_sa
  }

}

// Create the universe management sa token
resource "kubernetes_secret" "universe_management_sa_token" {
  depends_on = [kubernetes_service_account.universe_management_sa]
  metadata {
    name      = var.yba_universe_management_sa
    namespace = var.yba_universe_management_namespace
    annotations = {
      "kubernetes.io/service-account.name" = var.yba_universe_management_sa
    }
  }
  type = "kubernetes.io/service-account-token"
}

// Install the admin user crd
resource "kubectl_manifest" "yba_operator_admin_user_crd" {
  yaml_body = data.http.yba_operator_admin_user_crd_yaml.response_body
}

// Install the cloud provider crd
resource "kubectl_manifest" "yba_operator_cloud_provider_crd" {
  yaml_body = data.http.yba_operator_cloud_provider_crd_yaml.response_body
}

// Install the universe crd
resource "kubectl_manifest" "yba_operator_universe_crd" {
  yaml_body = data.http.yba_operator_universe_crd_yaml.response_body
}

// Namespace for YBA operator
resource "kubernetes_namespace" "yba_operator_namespace" {
  metadata {
    name = var.yba_operator_namespace
  }
}

// Config map for YBA operator pull secret
resource "kubernetes_config_map" "yba_operator_pull_secret_config_map" {
  //depends_on = [kubernetes_namespace.yba_operator_namespace]
  metadata {
    name      = "yugabyte-pull-secret-config-map"
    namespace = var.yba_operator_namespace
  }
  data = {
    "yugabyte-pull-secret.yaml" = <<EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: yugabyte-pull-secret-config-map
  namespace: ${var.yba_operator_namespace}
data:
  yugabyte-pull-secret.yaml: |
    apiVersion: v1
    kind: Secret
    metadata:
      name: yugabyte-k8s-pull-secret
    data:
      .dockerconfigjson: ${base64encode(var.yba_pull_secret)}
    type: kubernetes.io/dockerconfigjson
EOT
  }
}

// Config map for YBA kubeconfig
resource "kubernetes_config_map" "yba_kubeconfig_config_map" {
  //depends_on = [kubernetes_namespace.yba_operator_namespace]
  metadata {
    name      = "yugabyte-kubeconfig-config"
    namespace = var.yba_operator_namespace
  }
  data = {
    "yba-kubeconfig.yaml" = "${var.yba_kubeconfig}"
  }
}

// Install the YBA operator service account
resource "kubectl_manifest" "yba_operator_service_account" {
  depends_on = [
    kubectl_manifest.yba_operator_admin_user_crd,
    kubectl_manifest.yba_operator_cloud_provider_crd,
    kubectl_manifest.yba_operator_universe_crd,
    kubernetes_config_map.yba_operator_pull_secret_config_map
  ]
  yaml_body          = data.http.yba_operator_service_account_yaml.response_body
  override_namespace = var.yba_operator_namespace
}

// Install the YBA operator cluster role
resource "kubectl_manifest" "yba_operator_cluster_role" {
  depends_on = [
    kubectl_manifest.yba_operator_admin_user_crd,
    kubectl_manifest.yba_operator_cloud_provider_crd,
    kubectl_manifest.yba_operator_universe_crd,
    kubernetes_config_map.yba_operator_pull_secret_config_map
  ]
  yaml_body = data.http.yba_operator_cluster_role_yaml.response_body
}

// Install the YBA operator cluster role binding
resource "kubectl_manifest" "yba_operator_cluster_role_binding" {
  depends_on = [
    kubectl_manifest.yba_operator_service_account,
    kubectl_manifest.yba_operator_cluster_role
  ]
  yaml_body = data.http.yba_operator_cluster_role_binding_yaml.response_body
}

// Install the YBA operator deployment
resource "kubectl_manifest" "yba_operator_deployment" {
  depends_on = [
    kubectl_manifest.yba_operator_cluster_role_binding
  ]
  yaml_body          = data.http.yba_operator_deployment_yaml.response_body
  override_namespace = var.yba_operator_namespace
}

# Wait for a little bit for the YBA operator to start
# before we create the admin user
resource "time_sleep" "wait_for_yba_operator" {
  depends_on = [
    helm_release.yba,
    kubectl_manifest.yba_operator_deployment
  ]
  create_duration = "20s"
}

// Create the YBA admin user
resource "kubectl_manifest" "yba_admin_user" {
  depends_on = [time_sleep.wait_for_yba_operator]
  yaml_body  = <<EOT
apiVersion: ybaoperator.io/v1alpha1
kind: AdminUser
metadata:
  name: ${var.yba_admin_user_kubernetes_name}
  namespace: ${var.yba_operator_namespace}
spec:
  fullName: "${var.yba_admin_user_full_name}"
  password: "${var.yba_admin_user_password}"
  email: "${var.yba_admin_user_email}"
  environment: "${var.yba_admin_user_environment}"
EOT
}

