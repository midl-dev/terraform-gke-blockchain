terraform {
  required_version = ">= 0.12"
}

#
# Cluster options
# --------------------------------

variable "cluster_name" {
  type = string
  default = ""
}
variable "cluster_location" {
  type = string
  default = ""
}
variable "project" {
  type = string
  default = ""
}
variable "cluster_ca_certificate" {
  type = string
  default = ""
}
variable "kubernetes_endpoint" {
  type = string
  default = ""
}
#
# Monitoring options
# --------------------------------

variable "monitoring_slack_url" {
  type = string
  default = ""
  description = "slack api url to send prometheus alerts to"
}
