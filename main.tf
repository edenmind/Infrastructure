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
  name                   = "repository"
  subscription_tier_slug = "starter"
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
      "linkerd.io/inject" = "enabled"
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
