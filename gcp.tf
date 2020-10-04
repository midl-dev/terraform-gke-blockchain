## This file contains all the interactions with Google Cloud
provider "google" {
  region  = var.region
  project = var.project
  credentials = file(var.terraform_service_account_credentials)
}

provider "google-beta" {
  region  = var.region
  project = var.project
  credentials = file(var.terraform_service_account_credentials)
}

# Generate a random id for the project - GCP projects must have globally
# unique names
resource "random_id" "project_random" {
  prefix      = var.project_prefix
  byte_length = "8"
}

# Create the project if one isn't specified
resource "google_project" "blockchain_cluster" {
  count           = var.project != "" ? 0 : 1
  name            = random_id.project_random.hex
  project_id      = random_id.project_random.hex
  org_id          = var.org_id
  billing_account = var.billing_account
}

# Or use an existing project, if defined
data "google_project" "blockchain_cluster" {
  project_id = var.project != "" ? var.project : google_project.blockchain_cluster[0].project_id
}

# Create the blockchain_cluster service account
resource "google_service_account" "blockchain-server" {
  account_id   = "blockchain-server"
  display_name = "blockchain_cluster Server"
  project      = data.google_project.blockchain_cluster.project_id
}

# Create a service account key
resource "google_service_account_key" "blockchain_cluster" {
  service_account_id = google_service_account.blockchain-server.name
}

# Add the service account to the project
resource "google_project_iam_member" "service-account" {
  count   = length(var.service_account_iam_roles)
  project      = data.google_project.blockchain_cluster.project_id
  role    = element(var.service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.blockchain-server.email}"
}

# Enable required services on the project
resource "google_project_service" "service" {
  count   = length(var.project_services)
  project      = data.google_project.blockchain_cluster.project_id
  service = element(var.project_services, count.index)

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}

# Create an external NAT IP
resource "google_compute_address" "blockchain-nat" {
  count   = 2
  name    = "blockchain-nat-external-${count.index}"
  project      = data.google_project.blockchain_cluster.project_id
  region  = var.region

  depends_on = [google_project_service.service]
}

# Create a network for GKE
resource "google_compute_network" "blockchain-network" {
  name                    = "blockchain-network"
  project      = data.google_project.blockchain_cluster.project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.service]
}

# Create subnets
resource "google_compute_subnetwork" "blockchain-subnetwork" {
  name          = "blockchain-subnetwork"
  project      = data.google_project.blockchain_cluster.project_id
  network       = google_compute_network.blockchain-network.self_link
  region        = var.region
  ip_cidr_range = var.kubernetes_network_ipv4_cidr

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "blockchain-pods"
    ip_cidr_range = var.kubernetes_pods_ipv4_cidr
  }

  secondary_ip_range {
    range_name    = "blockchain-svcs"
    ip_cidr_range = var.kubernetes_services_ipv4_cidr
  }
}

# Create a NAT router so the nodes can reach DockerHub, etc
resource "google_compute_router" "blockchain-router" {
  name    = "blockchain-router"
  project      = data.google_project.blockchain_cluster.project_id
  region  = var.region
  network = google_compute_network.blockchain-network.self_link

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "blockchain-nat" {
  name    = "blockchain-nat-1"
  project      = data.google_project.blockchain_cluster.project_id
  router  = google_compute_router.blockchain-router.name
  region  = var.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.blockchain-nat.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.blockchain-subnetwork.self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]

    secondary_ip_range_names = [
      google_compute_subnetwork.blockchain-subnetwork.secondary_ip_range[0].range_name,
      google_compute_subnetwork.blockchain-subnetwork.secondary_ip_range[1].range_name,
    ]
  }
}

# Allow the k8s control plane to talk to kubelets, for prometheus admission rules
# https://github.com/prometheus-operator/prometheus-operator/issues/2711
resource "google_compute_firewall" "gke-master-to-kubelet" {
  name    = "k8s-master-to-kubelets"
  network    = google_compute_network.blockchain-network.self_link
  project      = data.google_project.blockchain_cluster.project_id

  description = "GKE master to kubelets"

  source_ranges = [var.kubernetes_masters_ipv4_cidr]

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  target_tags = ["gke-main"]
}

# Create the GKE cluster
resource "google_container_cluster" "blockchain_cluster" {
  provider = google-beta

  name     = "blockchain"
  project      = data.google_project.blockchain_cluster.project_id
  location = var.region
  node_locations = var.node_locations

  network    = google_compute_network.blockchain-network.self_link
  subnetwork = google_compute_subnetwork.blockchain-subnetwork.self_link

  initial_node_count = 1

  logging_service    = var.kubernetes_logging_service
  monitoring_service = var.kubernetes_monitoring_service

  # Disable legacy ACLs. The default is false, but explicitly marking it false
  # here as well.
  enable_legacy_abac = false

  release_channel {
    channel = var.release_channel
  }

  # Configure various addons
  addons_config {

    # Enable network policy configurations (like Calico).
    network_policy_config {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Disable basic authentication and cert-based authentication.
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Enable network policy configurations (like Calico) - for some reason this
  # has to be in here twice.
  network_policy {
    enabled = true
    provider = "CALICO"
  }

  # Set the maintenance window.
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.kubernetes_daily_maintenance_window
    }
  }

  # Allocate IPs in our subnetwork
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.blockchain-subnetwork.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.blockchain-subnetwork.secondary_ip_range[1].range_name
  }

  # Specify the list of CIDRs which can access the master's API
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.kubernetes_master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Configure the cluster to be private (not have public facing IPs)
  private_cluster_config {
    # This field is misleading. This prevents access to the master API from
    # any external IP. While that might represent the most secure
    # configuration, it is not ideal for most setups. As such, we disable the
    # private endpoint (allow the public endpoint) and restrict which CIDRs
    # can talk to that endpoint.
    enable_private_endpoint = false

    enable_private_nodes   = true
    master_ipv4_cidr_block = var.kubernetes_masters_ipv4_cidr
  }

  depends_on = [
    google_project_service.service,
    google_project_iam_member.service-account,
    google_compute_router_nat.blockchain-nat,
  ]
  remove_default_node_pool = true
  workload_identity_config {
    identity_namespace = "${data.google_project.blockchain_cluster.project_id}.svc.id.goog"
  }

  vertical_pod_autoscaling {
    enabled = true
  }
}


resource "google_container_node_pool" "blockchain_cluster_node_pool" {
  for_each = var.node_pools
  provider = google-beta
  project      = data.google_project.blockchain_cluster.project_id
  name       = each.key
  location   = var.region

  cluster    = google_container_cluster.blockchain_cluster.name
  node_count = each.value["node_count"]

  management {
     auto_repair = "true"
     auto_upgrade = "true"
  }

  node_config {
    machine_type    = each.value["instance_type"]
    service_account = google_service_account.blockchain-server.email

    # Set metadata on the VM to supply more entropy
    metadata = {
      google-compute-enable-virtio-rng = "true"
      disable-legacy-endpoints         = "true"
    }

    labels = {
      service = "blockchain_cluster"
    }
    preemptible  = false
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
    image_type = "COS"
    disk_type = "pd-standard"
    tags = [ "gke-main" ]

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "random_id" "rnd" {
  byte_length = 4
}
