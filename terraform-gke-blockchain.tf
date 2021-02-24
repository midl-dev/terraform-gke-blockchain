module "gcp_module" {
  source = "./gcp_module"
  org_id = var.org_id
  billing_account = var.billing_account
  terraform_service_account_credentials = var.terraform_service_account_credentials
  project = var.project
  project_prefix = var.project_prefix
  region = var.region
  node_locations = var.node_locations
  network_tier = var.network_tier
  service_account_iam_roles = var.service_account_iam_roles
  project_services = var.project_services
  kubernetes_daily_maintenance_window = var.kubernetes_daily_maintenance_window
  kubernetes_logging_service = var.kubernetes_logging_service
  kubernetes_monitoring_service = var.kubernetes_monitoring_service
  kubernetes_network_ipv4_cidr = var.kubernetes_network_ipv4_cidr
  kubernetes_pods_ipv4_cidr = var.kubernetes_pods_ipv4_cidr
  kubernetes_services_ipv4_cidr = var.kubernetes_services_ipv4_cidr
  kubernetes_masters_ipv4_cidr = var.kubernetes_masters_ipv4_cidr
  kubernetes_master_authorized_networks = var.kubernetes_master_authorized_networks
  release_channel = var.release_channel
  vpc_native = var.vpc_native
  node_pools = var.node_pools
}

module "k8s_module" {
  source = "./k8s_module"
  monitoring_slack_url = var.monitoring_slack_url 
  cluster_name = module.gcp_module.name
  cluster_location = module.gcp_module.location
  project = module.gcp_module.project
  kubernetes_endpoint = module.gcp_module.kubernetes_endpoint
  cluster_ca_certificate = module.gcp_module.cluster_ca_certificate
}
