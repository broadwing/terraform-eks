data "kubectl_path_documents" "aws_load_balancer_controller_resources" {
  pattern = "${path.module}/cluster_configs/aws-load-balancer-controller.tpl.yaml"
  vars = {
    cluster_name = var.environment
    alb_prefix   = var.alb_prefix
    alb_image    = var.aws_load_balancer_controller_image
  }
}

resource "kubectl_manifest" "aws_load_balancer_controller_resources" {
  count = var.aws_load_balancer_controller ? length(data.kubectl_path_documents.aws_load_balancer_controller_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.aws_load_balancer_controller_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}
