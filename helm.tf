# metrics-server
resource "helm_release" "metrics_server" {
  name        = "metrics-server"
  namespace   = "kube-system"
  repository  = "https://charts.bitnami.com/bitnami"
  chart       = "metrics-server"
  version     = "5.9.3"
  max_history = 10
  atomic      = true
  values = [
    file("helm/metrics-server.yaml"),
  ]
}

# cilium
resource "helm_release" "cilium" {
  name        = "cilium"
  namespace   = "kube-system"
  repository  = "https://helm.cilium.io/"
  chart       = "cilium"
  version     = "1.10.3"
  max_history = 10
  values = [
    file("helm/cilium.yaml")
  ]
}

# cert-manager
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name        = "cert-manager"
  namespace   = kubernetes_namespace.cert_manager.metadata[0].name
  repository  = "https://charts.jetstack.io"
  chart       = "cert-manager"
  version     = "1.5.3"
  max_history = 10
  values = [
    file("helm/cert-manager.yaml")
  ]
}

# kong
resource "kubernetes_namespace" "kong" {
  metadata {
    name = "kong"
  }
}

resource "helm_release" "kong" {
  name        = "kong"
  namespace   = kubernetes_namespace.kong.metadata[0].name
  repository  = "https://charts.konghq.com"
  chart       = "kong"
  version     = "2.3.0"
  max_history = 10
  atomic      = true
  values = [
    file("helm/kong.yaml"),
  ]
  depends_on = [
    helm_release.prometheus,
  ]
}

# localstack
resource "kubernetes_namespace" "localstack" {
  metadata {
    name = "localstack"
  }
}
resource "helm_release" "localstack" {
  name        = "localstack"
  namespace   = kubernetes_namespace.localstack.metadata[0].name
  repository  = "http://helm.localstack.cloud"
  chart       = "localstack"
  version     = "0.2.3"
  max_history = 10
  values = [
    file("helm/localstack.yaml")
  ]
}

# prometheus
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "helm_release" "prometheus" {
  name        = "prometheus"
  namespace   = kubernetes_namespace.prometheus.metadata[0].name
  repository  = "https://prometheus-community.github.io/helm-charts"
  chart       = "kube-prometheus-stack"
  version     = "18.0.1"
  max_history = 10
  values = [
    file("helm/prometheus.yaml")
  ]
}

# loki

# jaeger
