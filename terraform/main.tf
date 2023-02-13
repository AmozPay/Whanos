provider "digitalocean" {
	token = var.digitalocean_token
}

data "digitalocean_project" "project" {
  name = var.project_name
}

data "digitalocean_domain" "domain" {
  name = var.domain
}

#  JENKINS

resource "digitalocean_droplet" "jenkins_droplet" {
  name    = "jenkins"
  region  = "fra1"
  image   = "fedora-37-x64"
  size    = var.jenkins_size
  ssh_keys = [var.ssh_key_id]
}

resource "digitalocean_record" "jenkins_subdomain" {
  type = "A"
  name = "${var.jenkins_subdomain}"
  domain = data.digitalocean_domain.domain.id
  value = digitalocean_droplet.jenkins_droplet.ipv4_address
  ttl = 60
}


# DOCKER REGISTRY

# resource "digitalocean_droplet" "registry_droplet" {
#   name    = "registry"
#   region  = "fra1"
#   image   = "ubuntu-22-04-x64"
#   size    = var.registry_size
#   ssh_keys = [var.ssh_key_id]
# }


# resource "digitalocean_record" "registry_subdomain" {
#   type = "A"
#   name = "${var.registry_subdomain}"
#   domain = data.digitalocean_domain.domain.id
#   value = digitalocean_droplet.registry_droplet.ipv4_address
#   ttl = 60
# }


# KUBERNETES

# resource "digitalocean_kubernetes_cluster" "k8_app" {
#   name    = "app"
#   region  = "fra1"
#   version = "1.25.4-do.0"

#   node_pool {
#     name       = "autoscale-worker-pool"
#     size       = var.k8_node_size
#     auto_scale = true
#     min_nodes  = 2
#     max_nodes  = 3
#   }
# }

# resource "digitalocean_record" "k8_subdomain" {
#   type = "A"
#   name = "${var.k8_subdomain}"
#   domain = data.digitalocean_domain.domain.id
#   value = digitalocean_kubernetes_cluster.k8_app.ipv4_address
# }

resource "digitalocean_project_resources" "resources" {
  project = data.digitalocean_project.project.id
  resources = [
    # digitalocean_droplet.registry_droplet.urn,
    digitalocean_droplet.jenkins_droplet.urn,
  ]
}


# output "registry_ipv4" {
#   value = digitalocean_droplet.registry_droplet.ipv4_address
# }

output "jenkins_ipv4" {
  value = digitalocean_droplet.jenkins_droplet.ipv4_address
}

# output "k8_ipv4" {
#   value = digitalocean_kubernetes_cluster.k8_app.ipv4_address
# }
