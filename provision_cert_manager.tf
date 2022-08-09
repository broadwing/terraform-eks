data "kubectl_path_documents" "cert_manager_resources" {
  count = var.provision_cert_manager ? 1 : 0

  pattern = "${path.module}/cluster_configs/cert-manager.tpl.yaml"
  vars = {
  }
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.provision_cert_manager ? 1 : 0

  metadata {
    name = "cert-manager"
  }

  depends_on = [var.eks_module_cluster_id]
}

resource "kubectl_manifest" "cert_manager_resources" {
  count = var.provision_cert_manager ? length(data.kubectl_path_documents.cert_manager_resources[0].documents) : 0

  yaml_body = element(data.kubectl_path_documents.cert_manager_resources[0].documents, count.index)

  # Wait for rollout since other resources, like alb_controller need cert manager to exist first
  wait_for_rollout = true

  # Forces waiting for cluster to be available
  # and nodes to be up
  depends_on = [
    var.eks_module,
    resource.kubernetes_namespace.cert_manager,
  ]
}
