module "workers" {
  source = "git::https://github.com/squat/hetzner-cloud-kubeadm-workers.git?ref=458417dc1229914b97fa5393176acf69fe3c6e26"

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
