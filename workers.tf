module "workers" {
  source = "git::https://github.com/squat/hetzner-cloud-kubeadm-workers.git?ref=7f55a562014f7f1060a75e90be9a7df96857b376"

  api                = "${hcloud_load_balancer.lb.ipv4}:6443"
  token              = local.token
  ca_cert_hash       = local.ca_cert_hash
  node_count         = var.worker_count
  os_image           = var.os_image
  cluster_name       = var.cluster_name
  ssh_keys           = var.ssh_keys
  server_type        = var.worker_type
  datacenter         = var.datacenter
  subnet_id          = hcloud_network_subnet.subnet.id
  kubernetes_version = var.kubernetes_version
  release_version    = var.release_version
}
