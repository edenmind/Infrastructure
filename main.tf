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
variable "access_id" {}
variable "secret_key" {}

provider "digitalocean" {
  token = var.do_token

  spaces_access_id  = var.access_id
  spaces_secret_key = var.secret_key
}

resource "digitalocean_container_registry" "repository" {
  name                   = "openarabic"
  region                 = "ams3"
  subscription_tier_slug = "basic"
}

resource "digitalocean_database_cluster" "mongodb-example" {
  name       = "memorizer"
  engine     = "mongodb"
  version    = "5"
  size       = "db-s-1vcpu-1gb"
  region     = "ams3"
  node_count = 1
}

// create degitial ocean storage bucket
resource "digitalocean_spaces_bucket" "openarabic" {
  name   = "openarabic"
  region = "ams3"

  acl = "public-read"
}

resource "digitalocean_kubernetes_cluster" "openarabic" {
  name          = "openarabic"
  region        = "ams3"
  auto_upgrade  = true
  surge_upgrade = true
  version       = "1.25.4-do.0" # Grab the latest version: `doctl kubernetes options versions`

  node_pool {
    name       = "worker-pool"
    size       = "s-4vcpu-8gb"
    node_count = 1
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 2
  }
}

provider "kubernetes" {
  host  = digitalocean_kubernetes_cluster.openarabic.endpoint
  token = digitalocean_kubernetes_cluster.openarabic.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.openarabic.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = digitalocean_kubernetes_cluster.openarabic.endpoint
    token = digitalocean_kubernetes_cluster.openarabic.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.openarabic.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "kubernetes_namespace" "openarabic" {
  depends_on = [digitalocean_kubernetes_cluster.openarabic]
  metadata {
    labels = {
      "istio-injection" = "enabled"
    }
    name = "openarabic"
  }
}

resource "kubernetes_namespace" "loadtester" {
  depends_on = [digitalocean_kubernetes_cluster.openarabic]
  metadata {
    labels = {
      "istio-injection" = "enabled"
    }
    name = "loadtester"
  }
}

module "helm_charts" {
  source        = "./charts"
  slack_webhook = var.slack_webhook
}
