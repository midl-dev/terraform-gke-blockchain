output "kubernetes_endpoint" {
  value = module.gcp_module.kubernetes_endpoint
}

output "cluster_ca_certificate" {
  value = module.gcp_module.cluster_ca_certificate
}

output "name" {
  value = module.gcp_module.name
}

output "location" {
  value = module.gcp_module.location
}

output "node_locations" {
  value = module.gcp_module.node_locations
}

output "project" {
  value = module.gcp_module.project
}
