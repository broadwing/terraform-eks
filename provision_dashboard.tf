# Dashboard
module "provision_dashboard" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.dashboard

  template = file(
    "${path.module}/cluster_configs/kubernetes-dashboard.tpl.yaml",
  )

  vars = {
    wait_for_eks = null_resource.wait_for_eks.id
    cni          = var.remove_aws_vpc_cni ? "" : "aws"
  }
}

module "provision_heapster" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.dashboard

  template = file("${path.module}/cluster_configs/heapster.tpl.yaml")

  vars = {
    wait_for_eks = null_resource.wait_for_eks.id
    eks_endpoint = module.eks.cluster_endpoint
  }
}

module "provision_influxdb" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.dashboard

  template = file("${path.module}/cluster_configs/influxdb.tpl.yaml")

  vars = {
    wait_for_eks = null_resource.wait_for_eks.id
  }
}

module "provision_heapster_rbac" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.dashboard

  template = file("${path.module}/cluster_configs/heapster-rbac.tpl.yaml")

  vars = {
    wait_for_eks = null_resource.wait_for_eks.id
  }
}

module "provision_admin_service_account" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.dashboard

  template = file(
    "${path.module}/cluster_configs/eks-admin-service-account.tpl.yaml",
  )

  vars = {
    wait_for_eks = null_resource.wait_for_eks.id
  }
}

data "external" "dashboard-token" {
  count = var.dashboard == "true" ? 1 : 0

  program = ["${path.module}/bin/get_dashboard_token.sh"]

  query = {
    kubeconfig       = "${path.root}/${var.name}.kubeconfig"
    wait_for_account = module.provision_admin_service_account.md5
  }
}
