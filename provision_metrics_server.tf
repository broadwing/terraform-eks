data "kubectl_path_documents" "metrics_server_resources" {
  pattern = "${path.module}/cluster_configs/metrics-server.tpl.yaml"
  vars = {
    cni = var.calico_cni ? "aws" : ""
  }
}

resource "kubectl_manifest" "metrics_server_resources" {
  count = var.metrics_server ? length(data.kubectl_path_documents.metrics_server_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.metrics_server_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}
