data "kubectl_path_documents" "cluster_autoscaler_resources" {
  count = var.provision_cluster_autoscaler ? 1 : 0

  pattern = "${path.module}/cluster_configs/cluster-autoscaler-autodiscover.tpl.yaml"
  vars = {
    cluster_name = var.cluster_name
  }
}

resource "kubectl_manifest" "cluster_autoscaler_resources" {
  count = var.provision_cluster_autoscaler ? length(data.kubectl_path_documents.cluster_autoscaler_resources[0].documents) : 0

  yaml_body = element(data.kubectl_path_documents.cluster_autoscaler_resources[0].documents, count.index)

  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [
    var.eks_module_cluster_arn
  ]
}
