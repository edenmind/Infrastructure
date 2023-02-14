resource "helm_release" "metrics-server" { # helm search repo metrics-server
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/" # helm search repo metrics-server
  chart      = "metrics-server"
  version    = "3.8.3"
  namespace  = "kube-system"
}

resource "helm_release" "istio-base" { # helm search repo istio-base 
  name = "istio-base"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.16.2"
  create_namespace = true
  namespace        = "istio-system"
}

resource "helm_release" "istio-istiod" {
  name = "istio-istiod"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = "1.16.2"
  create_namespace = true
  namespace        = "istio-system"
}

resource "helm_release" "istio-ingress" {
  name = "istio-ingress"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = "1.16.2"
  create_namespace = true
  namespace        = "istio-system"
}

# TODO: Figure out how to install through TF
# kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.14/samples/addons/prometheus.yaml

resource "helm_release" "grafana" { # helm search repo loki-stack
  name = "grafana"

  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = "2.9.9"
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
    name  = "promtail.config.clients[0].url"
    value = "http://grafana-loki:3100/loki/api/v1/push"
  }
}

resource "helm_release" "loadtester" { # helm search repo loadtester
  name = "loadtester"

  repository       = "https://flagger.app"
  chart            = "loadtester"
  version          = "0.28.1"
  create_namespace = true
  namespace        = "loadtester"
}

resource "helm_release" "flagger" { # helm search repo flagger

  name = "flagger"

  repository       = "https://flagger.app"
  chart            = "flagger"
  version          = "1.28.0"
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
