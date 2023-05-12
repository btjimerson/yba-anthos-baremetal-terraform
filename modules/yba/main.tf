terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

// Namespace for YBA
resource "kubernetes_namespace" "yba_namespace" {
  metadata {
    name = var.yba_namespace
    labels = {
      istio-injection = "enabled"
    }
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
kind: Secret
metadata:
  name: yugabyte-k8s-pull-secret
data:
  .dockerconfigjson: $+base64encode(var.yba_pull_secret)}
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
  set {
    name  = "istioCompatibility.enabled"
    value = true
  }
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

// Install the YBA Kubernetes Operator helm chart
resource "helm_release" "yba_kubernetes_operator" {
  name       = "yba-operator"
  repository = "https://btjimerson.github.io/btjimerson-charts"
  chart      = "yba-kubernetes-operator"
  set {
    name  = "global.createNamespace"
    value = true
  }
  set {
    name  = "namespace.name"
    value = var.yba_operator_namespace
  }
  set {
    name  = "pullSecretConfigMap.pullSecret"
    value = base64encode(var.yba_pull_secret)
  }
  set {
    name  = "kubeconfigConfigMap.kubeconfig"
    value = var.yba_kubeconfig
  }
}

# Wait for a little bit for the YBA operator to start
# before we create the admin user
resource "time_sleep" "wait_for_yba_operator" {
  depends_on = [
    helm_release.yba,
    helm_release.yba_kubernetes_operator
  ]
  create_duration = "20s"
}


