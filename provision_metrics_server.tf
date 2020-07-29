module "provision_metrics_server" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.metrics_server

  template = file(
    "${path.module}/cluster_configs/metrics-server.tpl.yaml",
  )

  vars = {
    cni = var.remove_aws_vpc_cni ? "" : "aws"
  }

  use_system_kubectl = var.use_system_kubectl

  module_depends_on = [module.wait_for_eks.command]
}
