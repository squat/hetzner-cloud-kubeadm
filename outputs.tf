output "token" {
  value     = local.token
  sensitive = true
}

output "ca_cert_hash" {
  value = local.ca_cert_hash
}

output "api" {
  value = "${hcloud_load_balancer.lb.ipv4}:6443"
}

output "ips" {
  value = merge({
    for n in concat(module.controller-init, module.controllers-join) :
    n.name => n.ip
  }, module.workers.ips)
}
