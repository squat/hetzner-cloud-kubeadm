terraform {
  required_version = ">= 0.13"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.23.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
    sshcommand = {
      source  = "invidian/sshcommand"
      version = "0.2.2"
    }
  }
}
