module "provision_alb_ingress_controller_role" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.alb_ingress_controller

  template = file(
    "${path.module}/cluster_configs/alb-ingress-controller-role.tpl.yaml",
  )

  vars = {
    cluster_name = var.environment
    wait_for_eks = module.wait_for_eks.command_id
  }
}

module "provision_alb_ingress_controller" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.alb_ingress_controller

  template = file(
    "${path.module}/cluster_configs/alb-ingress-controller.tpl.yaml",
  )

  vars = {
    cluster_name = var.environment
    wait_for_eks = module.wait_for_eks.command_id
    alb_prefix   = var.alb_prefix
    alb_image    = var.alb_ingress_controller_image
  }
}
