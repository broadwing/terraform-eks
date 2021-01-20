data "kubectl_path_documents" "alb_ingress_controller_role_resources" {
  pattern = "${path.module}/cluster_configs/alb-ingress-controller-role.tpl.yaml"
  vars = {
  }
}

data "kubectl_path_documents" "alb_ingress_controller_resources" {
  pattern = "${path.module}/cluster_configs/alb-ingress-controller.tpl.yaml"
  vars = {
    cluster_name = var.environment
    alb_prefix   = var.alb_prefix
    alb_image    = var.alb_ingress_controller_image
  }
}

resource "kubectl_manifest" "alb_ingress_controller_role_resources" {
  count = var.alb_ingress_controller && !var.alb_ingress_controller_v2 ? length(data.kubectl_path_documents.alb_ingress_controller_role_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.alb_ingress_controller_role_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}

resource "kubectl_manifest" "alb_ingress_controller_resources" {
  count = var.alb_ingress_controller && !var.alb_ingress_controller_v2 ? length(data.kubectl_path_documents.alb_ingress_controller_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.alb_ingress_controller_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}

data "kubectl_path_documents" "alb_ingress_controller_resources_v2" {
  pattern = "${path.module}/cluster_configs/alb-ingress-controller-v2.tpl.yaml"
  vars = {
    cluster_name = var.environment
    alb_prefix   = var.alb_prefix
    alb_image    = var.alb_ingress_controller_image_v2
    cni          = var.alb_ingress_cni
  }
}

resource "kubectl_manifest" "alb_ingress_controller_resources_v2" {
  count = var.alb_ingress_controller && var.alb_ingress_controller_v2 ? length(data.kubectl_path_documents.alb_ingress_controller_resources_v2.documents) : 0

  yaml_body = element(data.kubectl_path_documents.alb_ingress_controller_resources_v2.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}

data "kubectl_path_documents" "alb_ingress_controller_resources_v2_webhookcert" {
  pattern = "${path.module}/cluster_configs/alb-ingress-controller-v2-cert-manager.tpl.yaml"

  vars = {
    cluster_name = var.environment
    alb_prefix   = var.alb_prefix
    alb_image    = var.alb_ingress_controller_image_v2
  }
}

resource "kubectl_manifest" "alb_ingress_controller_resources_v2_webhookcert" {
  count = var.alb_ingress_controller && var.alb_ingress_controller_v2 ? length(data.kubectl_path_documents.alb_ingress_controller_resources_v2_webhookcert.documents) : 0

  yaml_body = element(data.kubectl_path_documents.alb_ingress_controller_resources_v2_webhookcert.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id, kubectl_manifest.cert_manager_resources]
}
