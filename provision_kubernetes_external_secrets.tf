data "kubectl_path_documents" "kubernetes_external_secrets_resources" {
  pattern = "${path.module}/kubernetes-external-secrets/*.yaml"
  vars = {
    namespace          = var.external_secrets_namespace
    release_name       = var.external_secrets_release_name
    aws_default_region = var.external_secrets_aws_default_region
    aws_region         = var.external_secrets_aws_region
  }
}

resource "kubectl_manifest" "kubernetes_external_secrets_resources" {
  count = var.install_external_secrets ? length(data.kubectl_path_documents.kubernetes_external_secrets_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.kubernetes_external_secrets_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}
