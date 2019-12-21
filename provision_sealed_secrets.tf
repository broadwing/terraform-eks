# Seaeled Secrets
module "provision_sealed_secrets_controller" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.sealed_secrets_controller

  template = file(
    "${path.module}/cluster_configs/sealed-secrets-controller.tpl.yaml",
  )

  vars = {
  }
  module_depends_on = [module.wait_for_eks.command]
}

module "provision_sealed_secrets_crd" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.sealed_secrets_controller

  template = file("${path.module}/cluster_configs/sealed-secrets-crd.tpl.yaml")

  vars = {
  }

  module_depends_on = [module.wait_for_eks.command]
}
