output "kubernetes_endpoint" {
  value = "https://${google_container_cluster.blockchain_cluster.endpoint}"
}

output "cluster_ca_certificate" {
  value = base64decode(
    google_container_cluster.blockchain_cluster.master_auth[0].cluster_ca_certificate,
  )
}

output "name" {
  value = google_container_cluster.blockchain_cluster.name
}

output "location" {
  value = google_container_cluster.blockchain_cluster.location
}

output "node_locations" {
  value = var.node_locations
}

output "project" {
  value = google_container_cluster.blockchain_cluster.project
}
