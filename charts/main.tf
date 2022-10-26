resource "helm_release" "metrics-server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.8.2"
  namespace  = "kube-system"
}

resource "helm_release" "istio-base" {
  name = "istio-base"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.15.2"
  create_namespace = true
  namespace        = "istio-system"
}

resource "helm_release" "istio-istiod" {
  name = "istio-istiod"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = "1.15.2"
  create_namespace = true
  namespace        = "istio-system"
}

resource "helm_release" "istio-ingress" {
  name = "istio-ingress"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = "1.15.2"
  create_namespace = true
  namespace        = "istio-system"
}

# TODO: Figure out how to install through TF
# kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.14/samples/addons/prometheus.yaml

resource "helm_release" "grafana" {
  name = "grafana"

  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = "2.8.3"
  create_namespace = true
  namespace        = "grafana"

  set {
    name  = "grafana.enabled"
    value = true
  }

  set {
    name  = "grafana.persistence.enabled"
    value = true
  }

  set {
    name  = "grafana.persistence.size"
    value = "5Gi"
  }

  set {
    name  = "promtail.config.clients"
    value = "{url: http://grafana-loki:3100/loki/api/v1/push}"
  }
}

resource "helm_release" "loadtester" {
  name = "loadtester"

  repository       = "https://flagger.app"
  chart            = "loadtester"
  version          = "0.26.0"
  create_namespace = true
  namespace        = "loadtester"
}

resource "helm_release" "flagger" {

  name = "flagger"

  repository       = "https://flagger.app"
  chart            = "flagger"
  version          = "1.24.0"
  create_namespace = true
  namespace        = "istio-system"

  set {
    name  = "clusterName"
    value = "openarabic"
  }
  set {
    name  = "slack.user"
    value = "flagger"
  }
  set {
    name  = "slack.channel"
    value = "general"
  }
  set {
    name  = "slack.url"
    value = var.slack_webhook
  }
  set {
    name  = "metricsServer"
    value = "http://prometheus.istio-system:9090"
  }
  set {
    name  = "namespace"
    value = "openarabic"
  }
  set {
    name  = "meshProvider"
    value = "istio"
  }
}
