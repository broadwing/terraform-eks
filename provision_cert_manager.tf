data "kubectl_path_documents" "cert_manager_resources" {
  pattern = "${path.module}/cluster_configs/cert-manager.tpl.yaml"
  vars = {
    cni = var.remove_aws_vpc_cni ? "" : "aws"
  }
}

resource "kubectl_manifest" "cert_manager_resources" {
  count = var.cert_manager ? length(data.kubectl_path_documents.cert_manager_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.cert_manager_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}
