variable "digitalocean_token" {
    type = string
}

variable "ssh_key_id" {
    type = string
}

variable "domain" {
    type = string
}

variable "jenkins_subdomain" {
    type = string
    default = "jenkins"
}

variable "registry_subdomain" {
    type = string
    default = "registry"
}

variable "project_name" {
    type = string
}

variable "region" {
    type = string
    default = "fra1"
}

variable "jenkins_size" {
    type = string
    default = "s-1vcpu-2gb"
}

variable "registry_size" {
    type = string
    default = "s-1vcpu-1gb"
}

variable "k8_node_size" {
    type = string
    default = "s-2vcpu-2gb"
}

variable "k8_subdomain" {
    type = string
    default = "app"
}