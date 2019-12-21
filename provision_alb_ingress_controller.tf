module "provision_alb_ingress_controller_role" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.alb_ingress_controller

  template = file(
    "${path.module}/cluster_configs/alb-ingress-controller-role.tpl.yaml",
  )

  vars = {
    cluster_name = var.environment
  }

  module_depends_on = [module.wait_for_eks.command]
}

module "provision_alb_ingress_controller" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.alb_ingress_controller

  template = file(
    "${path.module}/cluster_configs/alb-ingress-controller.tpl.yaml",
  )

  vars = {
    cluster_name = var.environment
    alb_prefix   = var.alb_prefix
    alb_image    = var.alb_ingress_controller_image
  }

  module_depends_on = [module.wait_for_eks.command]

}
