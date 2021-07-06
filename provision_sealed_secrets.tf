data "kubectl_path_documents" "sealed_secrets_controller_resources" {
  pattern = "${path.module}/cluster_configs/sealed-secrets-controller.tpl.yaml"
  vars = {
    cni = var.remove_aws_vpc_cni ? "" : "aws"
  }
}

data "kubectl_path_documents" "sealed_secrets_crd_resources" {
  pattern = "${path.module}/cluster_configs/sealed-secrets-crd.tpl.yaml"
  vars = {
  }
}

resource "kubectl_manifest" "sealed_secrets_controller_resources" {
  count = var.sealed_secrets_controller ? length(data.kubectl_path_documents.sealed_secrets_controller_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.sealed_secrets_controller_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  server_side_apply = true

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}

resource "kubectl_manifest" "sealed_secrets_crd_resources" {
  count = var.sealed_secrets_controller ? length(data.kubectl_path_documents.sealed_secrets_crd_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.sealed_secrets_crd_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  server_side_apply = true

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}
