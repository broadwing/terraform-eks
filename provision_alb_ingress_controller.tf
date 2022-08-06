data "kubectl_path_documents" "aws_load_balancer_controller_resources" {
  pattern = "${path.module}/cluster_configs/alb-load-balancer-controller.tpl.yaml"
  vars = {
    cluster_name = var.environment
    alb_image    = var.aws_load_balancer_controller_image
    cni          = var.calico_cni ? "aws" : ""
  }
}

resource "kubectl_manifest" "aws_load_balancer_controller_resources" {
  count = var.aws_load_balancer_controller ? length(data.kubectl_path_documents.aws_load_balancer_controller_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.aws_load_balancer_controller_resources.documents, count.index)

  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [
    module.eks.cluster_id,
    kubectl_manifest.cert_manager_resources
  ]
}
