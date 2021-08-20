variable "cluster_name" {
  type        = string
  description = "Cluster name used as prefix for the node names"
}

# Hetzner

variable "load_balancer_type" {
  type        = string
  description = "The type of load balancer to use"
  default     = "lb11"
}

variable "datacenter" {
  type        = string
  description = "The region to deploy in"
}

variable "network_zone" {
  type        = string
  description = "The zone in which to create the network"
}

variable "controller_type" {
  type        = string
  default     = "cx11"
  description = "The server type to rent for controllers"
}

variable "worker_type" {
  type        = string
  default     = "cx11"
  description = "The server type to rent for workers"
}

variable "controller_count" {
  type        = number
  description = "Number of controllers (i.e. masters)"
  default     = 1
}

variable "worker_count" {
  type        = number
  description = "Number of workers"
  default     = 1
}

variable "controller_snippets" {
  type        = list(string)
  description = "Controller Container Linux Config snippets"
  default     = []
}

variable "worker_snippets" {
  type        = list(string)
  description = "Worker Container Linux Config snippets"
  default     = []
}

# configuration

variable "host_cidr" {
  type        = string
  description = "CIDR IPv4 range to assign to EC2 nodes"
  default     = "10.0.0.0/16"
}

variable "pod_cidr" {
  type        = string
  description = "CIDR IPv4 range to assign Kubernetes pods"
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = <<EOD
CIDR IPv4 range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for coredns.
EOD
  default     = "10.3.0.0/16"
}

variable "os_image" {
  type        = string
  description = "Channel for a Container Linux derivative (stable, beta, alpha)"
  default     = "stable"

  validation {
    condition     = contains(["stable", "beta", "alpha"], var.os_image)
    error_message = "The os_image must be stable, beta, or alpha."
  }
}

variable "ssh_keys" {
  type        = list(string)
  description = "SSH public keys for user 'core' and to register on Hetzner Cloud"
}

variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version to install"
}

variable "release_version" {
  type        = string
  default     = "v0.4.0"
  description = "The version of the Kubernetes release package"
}

variable "apiserver_extra_args" {
  type        = string
  description = "Extra arguments to pass to the API server as a JSON object, e.g. {\"oidc-username-claim\": \"email\", \"oidc-groups-claim\": \"groups\"}"
  default = ""
}
