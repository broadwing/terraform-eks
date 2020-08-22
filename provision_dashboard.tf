data "kubectl_path_documents" "dashboard_resources" {
  pattern = "${path.module}/cluster_configs/kubernetes-dashboard.tpl.yaml"
  vars = {
    cni = var.remove_aws_vpc_cni ? "" : "aws"
  }
}

data "kubectl_path_documents" "admin_service_account_resources" {
  pattern = "${path.module}/cluster_configs/eks-admin-service-account.tpl.yaml"
  vars = {
  }
}

resource "kubectl_manifest" "dashboard_resources" {
  count = var.dashboard ? length(data.kubectl_path_documents.dashboard_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.dashboard_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}

resource "kubectl_manifest" "admin_service_account_resources" {
  count = var.dashboard ? length(data.kubectl_path_documents.admin_service_account_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.admin_service_account_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}


data "kubernetes_secret" "dashboard_token" {
  metadata {
    name      = kubectl_manifest.admin_service_account_resources[2].name
    namespace = "kube-system"
  }

  depends_on = [kubectl_manifest.admin_service_account_resources]
}
