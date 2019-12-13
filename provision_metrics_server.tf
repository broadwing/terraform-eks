module "provision_metrics_server" {
  source     = "../kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.metrics_server

  template = file(
    "${path.module}/cluster_configs/metrics-server.tpl.yaml",
  )

  vars = {
    wait_for_eks = null_resource.wait_for_eks.id
  }
}

