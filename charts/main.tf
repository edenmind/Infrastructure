resource "helm_release" "metrics-server" {
  name = "metrics-server"

  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.8.2"
  create_namespace = true
  namespace        = "metrics-server"
}

resource "helm_release" "istio-base" {
  name = "istio-base"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.14.0"
  create_namespace = true
  namespace        = "istio-system"
}

resource "helm_release" "istio-istiod" {
  name = "istio-istiod"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = "1.14.0"
  create_namespace = true
  namespace        = "istio-system"
}

resource "helm_release" "istio-ingress" {
  name = "istio-ingress"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = "1.14.0"
  create_namespace = true
  namespace        = "istio-system"
}

# TODO: Figure out how to install through TF
# kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.14/samples/addons/prometheus.yaml

resource "helm_release" "loadtester" {
  name = "loadtester"

  repository       = "https://flagger.app"
  chart            = "loadtester"
  version          = "0.22.0"
  create_namespace = true
  namespace        = "loadtester"
}

resource "helm_release" "flagger" {
  name = "flagger"

  repository       = "https://flagger.app"
  chart            = "flagger"
  version          = "1.21.0"
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
    value = "https://hooks.slack.com/services/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"
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
