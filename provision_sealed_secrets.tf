data "kubectl_path_documents" "sealed_secrets_resources" {
  pattern = "${path.module}/cluster_configs/sealed-secrets.tpl.yaml"
  vars = {
    cni = var.calico_cni ? "aws" : ""
  }
}


resource "kubectl_manifest" "sealed_secrets_resources" {
  count = var.sealed_secrets_controller ? length(data.kubectl_path_documents.sealed_secrets_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.sealed_secrets_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}
