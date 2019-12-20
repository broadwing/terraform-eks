module "provision_metrics_server" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.metrics_server

  template = file(
    "${path.module}/cluster_configs/metrics-server.tpl.yaml",
  )

  vars = {
    wait_for_eks = module.wait_for_eks.command_id
  }
}
