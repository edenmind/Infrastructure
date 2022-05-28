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

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_kubernetes_cluster" "openarabic" {
  name   = "openarabic"
  region = "ams3"
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.22.8-do.1"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3

    taint {
      key    = "workloadKind"
      value  = "database"
      effect = "NoSchedule"
    }
  }
}
