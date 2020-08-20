terraform {
  required_version = ">= 0.12"
}

#
# Google Cloud Platform options
# ------------------------------

variable "org_id" {
  type        = string
  description = "Organization ID."
}

variable "billing_account" {
  type        = string
  description = "Billing account ID."
}

variable "terraform_service_account_credentials" {
  type = string
  description = "path to terraform service account file, created following the instructions in https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform"
}

variable "project" {
  type        = string
  default     = ""
  description = "Project ID where Terraform is authenticated to run to create additional projects. If provided, Terraform will great the GKE and Tezos cluster inside this project. If not given, Terraform will generate a new project."
}

variable "project_prefix" {
  type = string
  default = "blkchain"
  description = "A project prefix. If the project id is not given, the created project will be this prefix followed by a random string"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Region in which to create the cluster."
}

variable "node_locations" {
  type  = list
  default = [ "us-central1-b", "us-central1-f" ]
  description = "List of locations within the regions where to deploy the nodes."
}

variable "service_account_iam_roles" {
  type = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer"
  ]
  description = "List of IAM roles to assign to the service account."
}

variable "project_services" {
  type = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "dns.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
  description = "List of services to enable on the project."
}

#
# Kubernetes options
# ------------------------------

variable "kubernetes_daily_maintenance_window" {
  type        = string
  default     = "06:00"
  description = "Maintenance window for GKE."
}

variable "kubernetes_logging_service" {
  type        = string
  default     = "logging.googleapis.com/kubernetes"
  description = "Name of the logging service to use. By default this uses the new Stackdriver GKE beta."
}

variable "kubernetes_monitoring_service" {
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
  description = "Name of the monitoring service to use. By default this uses the new Stackdriver GKE beta."
}

variable "kubernetes_network_ipv4_cidr" {
  type        = string
  default     = "10.0.96.0/22"
  description = "IP CIDR block for the subnetwork. This must be at least /22 and cannot overlap with any other IP CIDR ranges."
}

variable "kubernetes_pods_ipv4_cidr" {
  type        = string
  default     = "10.0.92.0/22"
  description = "IP CIDR block for pods. This must be at least /22 and cannot overlap with any other IP CIDR ranges."
}

variable "kubernetes_services_ipv4_cidr" {
  type        = string
  default     = "10.0.88.0/22"
  description = "IP CIDR block for services. This must be at least /22 and cannot overlap with any other IP CIDR ranges."
}

variable "kubernetes_masters_ipv4_cidr" {
  type        = string
  default     = "10.0.82.0/28"
  description = "IP CIDR block for the Kubernetes master nodes. This must be exactly /28 and cannot overlap with any other IP CIDR ranges."
}

variable "kubernetes_master_authorized_networks" {
  type = list(object({
    display_name = string
    cidr_block   = string
  }))

  default = [
    {
      display_name = "Anyone"
      cidr_block   = "0.0.0.0/0"
    },
  ]

  description = "List of CIDR blocks to allow access to the master's API endpoint. This is specified as a slice of objects, where each object has a display_name and cidr_block attribute. The default behavior is to allow anyone (0.0.0.0/0) access to the endpoint. You should restrict access to external IPs that need to access the cluster."
}

#
# Node pool option
# --------------------------------

variable "node_pools" {
  type = map
  default =  { "blockchain_pool" : { "node_count": 1, "instance_type": "e2-standard-2" } }
  description = "A map of node pools. Lets you define several of them for better isolation"
}

#
# Monitoring options
# --------------------------------

variable "monitoring_slack_url" {
  type = string
  default = ""
  description = "slack api url to send prometheus alerts to"
}
