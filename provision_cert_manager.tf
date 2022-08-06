data "kubectl_path_documents" "cert_manager_resources" {
  pattern = "${path.module}/cluster_configs/cert-manager.tpl.yaml"
  vars = {
    cni = var.calico_cni ? "aws" : ""
  }
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.dashboard ? 1 : 0

  metadata {
    name = "cert-manager"
  }

  depends_on = [module.eks.cluster_id]
}

resource "kubectl_manifest" "cert_manager_resources" {
  count = var.cert_manager ? length(data.kubectl_path_documents.cert_manager_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.cert_manager_resources.documents, count.index)

  # Wait for rollout since other resources, like alb_controller need cert manager to exist first
  wait_for_rollout = true

  # Forces waiting for cluster to be available
  # and nodes to be up
  depends_on = [
    module.eks.cluster_id,
    resource.kubernetes_namespace.cert_manager,
    module.eks.node_groups,
    module.eks.workers_asg_arns
  ]
}
