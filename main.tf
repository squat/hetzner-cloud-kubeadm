locals {
  token        = "${random_password.token-1.result}.${random_password.token-2.result}"
  ca_cert_hash = "sha256:${trimspace(data.sshcommand_command.ca-cert-hash.result)}"
  count_init   = min(var.controller_count, 1)
  count_join   = max(var.controller_count - 1, 0)
}

module "controller-init" {
  source = "git::https://github.com/squat/hetzner-cloud-flatcar-linux.git?ref=985afb1c7bb4a0159ae77acf6a6be6011bf859ed"
  count  = local.count_init

  name = "${var.cluster_name}-controller-${count.index}"

  # Hetzner
  datacenter  = var.datacenter
  server_type = var.controller_type
  os_image    = var.os_image

  # Configuration
  ssh_keys = concat([tls_private_key.ssh.public_key_openssh], var.ssh_keys)
  snippets = [
    data.template_file.controller-config[count.index].rendered,
    data.template_file.kubeadm-config-init[0].rendered
  ]
}

module "controllers-join" {
  source = "git::https://github.com/squat/hetzner-cloud-flatcar-linux.git?ref=985afb1c7bb4a0159ae77acf6a6be6011bf859ed"
  count  = local.count_join

  name = "${var.cluster_name}-controller-${count.index + 1}"

  # Hetzner
  datacenter  = var.datacenter
  server_type = var.controller_type
  os_image    = var.os_image

  # Configuration
  ssh_keys = concat([tls_private_key.ssh.public_key_openssh], var.ssh_keys)
  snippets = [
    data.template_file.controller-config[count.index].rendered,
    data.template_file.kubeadm-config-join[count.index].rendered
  ]
}

data "template_file" "controller-config" {
  count    = var.controller_count
  template = file("${path.module}/cl/controller.yaml")

  vars = {
    name    = "${var.cluster_name}-${count.index}"
    release = var.release_version
    version = var.kubernetes_version
  }
}

data "template_file" "kubeadm-config-init" {
  count    = local.count_init
  template = file("${path.module}/cl/kubeadm-init.yaml")

  vars = {
    name            = "${var.cluster_name}-controller-${count.index}"
    api             = "${hcloud_load_balancer.lb.ipv4}:6443"
    token           = local.token
    certificate_key = random_password.certificate_key.result
    pod_cidr        = var.pod_cidr
    service_cidr    = var.service_cidr
    extra_args      = var.apiserver_extra_args
  }
}

data "template_file" "kubeadm-config-join" {
  count    = local.count_join
  template = file("${path.module}/cl/kubeadm-join.yaml")

  vars = {
    name            = "${var.cluster_name}-controller-${count.index + 1}"
    api             = "${hcloud_load_balancer.lb.ipv4}:6443"
    token           = local.token
    ca_cert_hash    = local.ca_cert_hash
    certificate_key = random_password.certificate_key.result
  }
}

resource "random_password" "certificate_key" {
  length           = 64
  number           = false
  lower            = false
  upper            = false
  special          = true
  override_special = "0123456789abcdef"
}

resource "random_password" "token-1" {
  length  = 6
  number  = true
  lower   = true
  special = false
  upper   = false
}

resource "random_password" "token-2" {
  length  = 16
  number  = true
  lower   = true
  special = false
  upper   = false
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Init the controllers to the cluster only once the private
# network has been attached.
resource "null_resource" "init" {
  count      = local.count_init
  depends_on = [hcloud_server_network.init]

  connection {
    private_key = tls_private_key.ssh.private_key_pem
    host        = module.controller-init[0].ip.ipv4
    user        = "core"
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart systemd-networkd",
      "sudo systemctl start kubeadm-init",
    ]
  }
}

data "sshcommand_command" "ca-cert-hash" {
  command     = "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'"
  private_key = tls_private_key.ssh.private_key_pem
  host        = module.controller-init[0].ip.ipv4
  user        = "core"
  depends_on  = [null_resource.init]
}

# Join the controllers to the cluster only once the private
# network has been attached.
resource "null_resource" "join" {
  count      = local.count_join
  depends_on = [hcloud_load_balancer_target.init, hcloud_server_network.join]

  connection {
    private_key = tls_private_key.ssh.private_key_pem
    host        = module.controllers-join[count.index].ip.ipv4
    user        = "core"
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart systemd-networkd",
      "sudo systemctl start kubeadm-join",
    ]
  }
}
