# Seaeled Secrets
module "provision_sealed_secrets_controller" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.sealed_secrets_controller

  template = file(
    "${path.module}/cluster_configs/sealed-secrets-controller.tpl.yaml",
  )

  vars = {
    wait_for_eks = null_resource.wait_for_eks.id
  }
}

module "provision_sealed_secrets_crd" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.sealed_secrets_controller

  template = file("${path.module}/cluster_configs/sealed-secrets-crd.tpl.yaml")

  vars = {
    wait_for_eks = null_resource.wait_for_eks.id
  }
}
