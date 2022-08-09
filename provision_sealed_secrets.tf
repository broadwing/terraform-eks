data "kubectl_path_documents" "sealed_secrets_resources" {
  count = var.provision_sealed_secrets_controller ? 1 : 0

  pattern = "${path.module}/cluster_configs/sealed-secrets.tpl.yaml"
  vars = {
  }
}


resource "kubectl_manifest" "sealed_secrets_resources" {
  count = var.provision_sealed_secrets_controller ? length(data.kubectl_path_documents.sealed_secrets_resources[0].documents) : 0

  yaml_body = element(data.kubectl_path_documents.sealed_secrets_resources[0].documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [var.eks_module_cluster_id]
}
