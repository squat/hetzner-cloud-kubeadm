resource "hcloud_network" "network" {
  name     = var.cluster_name
  ip_range = var.host_cidr
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.host_cidr
}

resource "hcloud_server_network" "init" {
  count     = local.count_init
  server_id = module.controller-init[count.index].id
  subnet_id = hcloud_network_subnet.subnet.id
  ip        = cidrhost(split("-", hcloud_network_subnet.subnet.id)[1], count.index + var.worker_count + 2)
}

resource "hcloud_server_network" "join" {
  count     = local.count_join
  server_id = module.controllers-join[count.index].id
  subnet_id = hcloud_network_subnet.subnet.id
  ip        = cidrhost(split("-", hcloud_network_subnet.subnet.id)[1], count.index + 1 + var.worker_count + 2)
}

resource "hcloud_load_balancer" "lb" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = var.load_balancer_type
  network_zone       = var.network_zone
}

resource "hcloud_load_balancer_target" "init" {
  count            = local.count_init
  type             = "server"
  load_balancer_id = hcloud_load_balancer.lb.id
  server_id        = module.controller-init[count.index].id
}

resource "hcloud_load_balancer_target" "join" {
  count            = local.count_join
  type             = "server"
  load_balancer_id = hcloud_load_balancer.lb.id
  server_id        = module.controllers-join[count.index].id
}

resource "hcloud_load_balancer_service" "apiserver" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 10
    retries  = 3
    timeout  = 3
  }
}
