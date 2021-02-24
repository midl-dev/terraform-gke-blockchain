# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {
}

provider "kubernetes" {
  host             = var.kubernetes_endpoint
  cluster_ca_certificate = var.cluster_ca_certificate
  token = data.google_client_config.default.access_token
}

resource "kubernetes_namespace" "flux_namespace" {
  metadata {
    name = "flux"
  }
}

resource "kubernetes_namespace" "monitoring_namespace" {
  metadata {
    name = "monitoring"
  }
  depends_on = [ kubernetes_namespace.flux_namespace ]
}

resource "null_resource" "deploy_prometheus" {
  provisioner "local-exec" {

    command = <<EOF
set -e
set -x
gcloud container clusters get-credentials "${var.cluster_name}" --region="${var.cluster_location}" --project="${var.project}"

cd ${path.module}
# Install Helm operator in order to install the prometheus operator
# Instructions from https://docs.fluxcd.io/projects/helm-operator/en/latest/get-started/using-yamls/
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/1.1.0/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/1.1.0/deploy/rbac.yaml
kubectl apply -f helm-operator.yaml

cat <<'EOPO' > prometheus-operator.yaml
${templatefile("${path.module}/prometheus-operator.yaml.tmpl",
   { "monitoring_slack_url": var.monitoring_slack_url } ) }
EOPO
kubectl apply -f prometheus-operator.yaml
rm prometheus-operator.yaml
EOF

  }
  depends_on = [ kubernetes_namespace.monitoring_namespace ]
}
