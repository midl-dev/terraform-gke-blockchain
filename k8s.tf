resource "kubernetes_namespace" "flux_namespace" {
  metadata {
    name = "flux"
  }
  depends_on = [ google_container_node_pool.blockchain_cluster_node_pool ]
}

resource "kubernetes_namespace" "monitoring_namespace" {
  metadata {
    name = "monitoring"
  }
  depends_on = [ google_container_node_pool.blockchain_cluster_node_pool ]
}

resource "null_resource" "deploy_prometheus" {
  provisioner "local-exec" {

    command = <<EOF
set -e
set -x
gcloud container clusters get-credentials "${google_container_cluster.blockchain_cluster.name}" --region="${google_container_cluster.blockchain_cluster.location}" --project="${google_container_cluster.blockchain_cluster.project}"

cd ${path.module}
# Install Helm operator in order to install the prometheus operator
# Instructions from https://docs.fluxcd.io/projects/helm-operator/en/latest/get-started/using-yamls/
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/1.1.0/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/1.1.0/deploy/rbac.yaml
kubectl apply -f helm-operator.yaml

kubectl apply -f prometheus-operator.yaml
EOF

  }
  depends_on = [ kubernetes_namespace.flux_namespace, kubernetes_namespace.monitoring_namespace ]
}
