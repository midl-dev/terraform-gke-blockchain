output "kubernetes_endpoint" {
  value = google_container_cluster.blockchain_cluster.endpoint
}

output "cluster_ca_certificate" {
  value = base64decode(
    google_container_cluster.blockchain_cluster.master_auth[0].cluster_ca_certificate,
  )
}

output "token" {
  value = data.google_client_config.current.access_token
}

output "cluster_name" {
  value = google_container_cluster.blockchain_cluster.name
}

output "cluster_location" {
  value = google_container_cluster.blockchain_cluster.location
}
