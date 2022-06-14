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

resource "digitalocean_kubernetes_cluster" "openarabic" {
  name   = "openarabic"
  region = "ams3"
  # Grab the latest version: `doctl kubernetes options versions`
  version = "1.22.8-do.1"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-4gb"
    node_count = 2
  }
}

resource "digitalocean_container_registry" "repository" {
  name                   = "openarabic"
  region                 = "ams3"
  subscription_tier_slug = "basic"
}

data "digitalocean_kubernetes_cluster" "openarabic" {
  name       = "openarabic"
  depends_on = [digitalocean_kubernetes_cluster.openarabic]
}

provider "digitalocean" {
  token = var.do_token
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
resource "kubernetes_namespace" "openarabic" {
  metadata {
    labels = {
      "istio-injection" = "enabled"
    }
    name = "openarabic"
  }
  depends_on = [digitalocean_kubernetes_cluster.openarabic]
}

resource "kubernetes_namespace" "loadtester" {
  metadata {
    labels = {
      "istio-injection" = "enabled"
    }
    name = "loadtester"
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
  depends_on       = [digitalocean_kubernetes_cluster.openarabic]
}

resource "helm_release" "istio-ingress" {
  name = "istio-ingress"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = "1.14.0"
  create_namespace = true
  namespace        = "istio-system"
  depends_on       = [digitalocean_kubernetes_cluster.openarabic]
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
  depends_on       = [digitalocean_kubernetes_cluster.openarabic]
}

resource "helm_release" "flagger" {
  name = "flagger"

  repository       = "https://flagger.app"
  chart            = "flagger"
  version          = "1.21.0"
  create_namespace = true
  namespace        = "istio-system"
  depends_on       = [digitalocean_kubernetes_cluster.openarabic]

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
