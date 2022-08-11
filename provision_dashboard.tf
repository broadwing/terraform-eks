data "kubectl_path_documents" "dashboard_resources" {
  count = var.provision_dashboard ? 1 : 0

  pattern = "${path.module}/cluster_configs/kubernetes-dashboard.tpl.yaml"
  vars = {
  }
}

data "kubectl_path_documents" "admin_service_account_resources" {
  count = var.provision_dashboard ? 1 : 0

  pattern = "${path.module}/cluster_configs/eks-admin-service-account.tpl.yaml"
  vars = {
  }
}

resource "kubernetes_namespace" "dashboard" {
  count = var.provision_dashboard ? 1 : 0

  metadata {
    name = "kubernetes-dashboard"
  }

  depends_on = [var.eks_module_cluster_id]
}

resource "kubectl_manifest" "dashboard_resources" {
  count = var.provision_dashboard ? length(data.kubectl_path_documents.dashboard_resources[0].documents) : 0

  yaml_body = element(data.kubectl_path_documents.dashboard_resources[0].documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [var.eks_module_cluster_id, kubernetes_namespace.dashboard]

  lifecycle {
    ignore_changes = [
      # Ignore changes to yaml_incluster because the service itself changes it
      yaml_incluster,
    ]
  }

}

resource "kubectl_manifest" "admin_service_account_resources" {
  count = var.provision_dashboard ? length(data.kubectl_path_documents.admin_service_account_resources[0].documents) : 0

  yaml_body = element(data.kubectl_path_documents.admin_service_account_resources[0].documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [var.eks_module_cluster_id, kubernetes_namespace.dashboard]
}


data "kubernetes_secret" "dashboard_token" {
  count = var.provision_dashboard && var.get_dashboard_token ? 1 : 0

  metadata {
    name      = kubectl_manifest.admin_service_account_resources[2].name
    namespace = "kube-system"
  }

  depends_on = [kubectl_manifest.admin_service_account_resources, kubernetes_namespace.dashboard]
}
