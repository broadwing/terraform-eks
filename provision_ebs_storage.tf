data "kubectl_path_documents" "ebs_resources" {
  count = var.provision_ebs_storage ? 1 : 0

  pattern = "${path.module}/cluster_configs/ebs-storage-class.tpl.tpl.yaml"
  vars = {
    encrypted = var.ebs_default_encrypted
  }
}

resource "kubectl_manifest" "ebs_resources" {
  count = var.provision_ebs_storage ? length(data.kubectl_path_documents.ebs_resources[0].documents) : 0

  force_new = true

  yaml_body = element(data.kubectl_path_documents.ebs_resources[0].documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [var.eks_module_cluster_arn]
}
