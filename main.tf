terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
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
variable "slack_webhook" {}

provider "digitalocean" {
  token = var.do_token
}
resource "digitalocean_kubernetes_cluster" "openarabic" {
  name          = "openarabic"
  region        = "ams3"
  auto_upgrade  = true
  surge_upgrade = true
  version       = "1.24.4-do.0" # Grab the latest version: `doctl kubernetes options versions`

  node_pool {
    name       = "worker-pool"
    size       = "s-4vcpu-8gb"
    node_count = 1
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 2
  }
}

# data "digitalocean_kubernetes_cluster" "openarabic" {
#   name = "openarabic"
# }

# provider "kubernetes" {
#   host  = data.digitalocean_kubernetes_cluster.openarabic.endpoint
#   token = data.digitalocean_kubernetes_cluster.openarabic.kube_config[0].token
#   cluster_ca_certificate = base64decode(
#     data.digitalocean_kubernetes_cluster.openarabic.kube_config[0].cluster_ca_certificate
#   )
# }

# provider "helm" {
#   kubernetes {
#     host  = data.digitalocean_kubernetes_cluster.openarabic.endpoint
#     token = data.digitalocean_kubernetes_cluster.openarabic.kube_config[0].token
#     cluster_ca_certificate = base64decode(
#       data.digitalocean_kubernetes_cluster.openarabic.kube_config[0].cluster_ca_certificate
#     )
#   }
# }

resource "kubernetes_namespace" "openarabic" {
  metadata {
    labels = {
      "istio-injection" = "enabled"
    }
    name = "openarabic"
  }
}

resource "kubernetes_namespace" "loadtester" {
  metadata {
    labels = {
      "istio-injection" = "enabled"
    }
    name = "loadtester"
  }
}

resource "digitalocean_container_registry" "repository" {
  name                   = "openarabic"
  region                 = "ams3"
  subscription_tier_slug = "basic"
}


# module "helm_charts" {
#   source        = "./charts"
#   slack_webhook = var.slack_webhook
# }
