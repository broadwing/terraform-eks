data "kubectl_path_documents" "ebs_resources" {
  pattern = "${path.module}/cluster_configs/ebs-storage-class.tpl.tpl.yaml"
  vars = {
    encrypted = var.ebs_default_encrypted
  }
}

resource "kubectl_manifest" "ebs_resources" {
  count     = length(data.kubectl_path_documents.ebs_resources.documents)
  force_new = true

  yaml_body = element(data.kubectl_path_documents.ebs_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}
