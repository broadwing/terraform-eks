data "kubectl_path_documents" "flux_resources" {
  pattern = "${path.module}/cluster_configs/flux.tpl.yaml"
  vars = {
    flux_git_user            = var.flux_git_user
    flux_git_url             = var.flux_git_url
    flux_git_path            = var.flux_git_path
    flux_git_branch          = var.flux_git_branch
    flux_manifest_generation = var.flux_manifest_generation ? "true" : "false"
  }
}

resource "kubectl_manifest" "flux_resources" {
  count = var.flux ? length(data.kubectl_path_documents.flux_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.flux_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  server_side_apply = true

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id, kubernetes_secret.flux_deploy_key, kubernetes_namespace.flux]
}

resource "kubernetes_namespace" "flux" {
  count = var.flux ? 1 : 0

  metadata {
    name = "flux"
  }

  depends_on = [module.eks.cluster_id]
}

resource "tls_private_key" "flux_deploy_key" {
  count     = var.flux ? 1 : 0
  algorithm = "RSA"
}

resource "kubernetes_secret" "flux_deploy_key" {
  count = var.flux ? 1 : 0

  metadata {
    name      = "flux-git-deploy"
    namespace = "flux"
  }

  data = {
    identity = tls_private_key.flux_deploy_key[0].private_key_pem
  }

  depends_on = [module.eks.cluster_id, kubernetes_namespace.flux]
}
