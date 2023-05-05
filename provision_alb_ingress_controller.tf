data "kubectl_path_documents" "aws_load_balancer_controller_resources" {
  count = var.provision_aws_load_balancer_controller ? 1 : 0

  pattern = "${path.module}/cluster_configs/alb-load-balancer-controller.tpl.yaml"
  vars = {
    cluster_name = var.cluster_name
    alb_image    = var.aws_load_balancer_controller_image
  }
}

resource "kubectl_manifest" "aws_load_balancer_controller_resources" {
  count = var.provision_aws_load_balancer_controller ? length(data.kubectl_path_documents.aws_load_balancer_controller_resources[0].documents) : 0

  yaml_body = element(data.kubectl_path_documents.aws_load_balancer_controller_resources[0].documents, count.index)

  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [
    var.eks_module_cluster_arn,
    kubectl_manifest.cert_manager_resources
  ]
}
