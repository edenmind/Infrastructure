terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  cloud {
    organization = "edenmind"

    workspaces {
      name = "openarabic"
    }
  }
}

variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_kubernetes_cluster" "openarabic" {
  name   = "openarabic"
  region = "ams3"
  # Grab the latest version: `doctl kubernetes options versions`
  version = "1.22.8-do.1"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-8gb"
    node_count = 2
  }
}

data "digitalocean_kubernetes_cluster" "openarabic" {
  name = "openarabic"
}
provider "kubernetes" {
  host  = data.digitalocean_kubernetes_cluster.openarabic.endpoint
  token = data.digitalocean_kubernetes_cluster.openarabic.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.openarabic.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = data.digitalocean_kubernetes_cluster.openarabic.endpoint
    token = data.digitalocean_kubernetes_cluster.openarabic.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.openarabic.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "kubernetes_namespace" "gateway" {
  metadata {
    labels = {
      istio-injection = "enabled"
    }
    name = "gateway"
  }

  depends_on = [digitalocean_kubernetes_cluster.openarabic]
}

resource "kubernetes_namespace" "openarabic" {
  metadata {
    labels = {
      istio-injection = "enabled"
    }
    name = "openarabic"
  }

  depends_on = [digitalocean_kubernetes_cluster.openarabic]
}

resource "helm_release" "metrics-server" {
  name = "metrics-server"

  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.8.2"
  create_namespace = true
  namespace        = "metrics-server"
  depends_on       = [digitalocean_kubernetes_cluster.openarabic]
}

resource "helm_release" "prometheus-stack" {
  name = "prometheus-stack"

  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "35.5.1"
  create_namespace = true
  namespace        = "prometheus-stack"
  depends_on       = [digitalocean_kubernetes_cluster.openarabic]

  set {
    name  = "serviceMonitorNamespaceSelector"
    value = ""
  }

  set {
    name  = "serviceMonitorSelector"
    value = ""
  }
}

resource "helm_release" "istio-base" {
  name = "istio-base"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.14.0"
  create_namespace = true
  namespace        = "istio-system"
  depends_on       = [digitalocean_kubernetes_cluster.openarabic]
}

resource "helm_release" "istio-istiod" {
  name = "istio-istiod"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = "1.14.0"
  create_namespace = true
  namespace        = "istio-system"
  depends_on       = [digitalocean_kubernetes_cluster.openarabic, helm_release.istio-base]
}

resource "helm_release" "istio-ingress" {
  name = "istio-ingress"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = "1.14.0"
  create_namespace = false
  namespace        = "gateway"
  depends_on       = [digitalocean_kubernetes_cluster.openarabic, helm_release.istio-istiod, kubernetes_namespace.gateway]
}

resource "helm_release" "flagger" {
  name = "flagger"

  repository       = "https://flagger.app"
  chart            = "flagger"
  version          = "1.21.0"
  create_namespace = false
  namespace        = "istio-system"
  depends_on       = [digitalocean_kubernetes_cluster.openarabic, helm_release.istio-ingress]

  set {
    name  = "meshProvider"
    value = "istio"
  }
  set {
    name  = "metricsServer"
    value = "http://prometheus-stack-kube-prom-prometheus.prometheus-stack:9090"
  }
}
