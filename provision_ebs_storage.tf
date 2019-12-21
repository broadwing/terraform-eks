# ebs-storage
module "provision_ebs" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  template = file("${path.module}/cluster_configs/ebs-storage-class.tpl.yaml")

  extra_command = "kubectl --namespace kube-system delete storageclasses.storage.k8s.io gp2"

  vars = {
    encrypted = var.ebs_default_encrypted
  }

  module_depends_on = [module.wait_for_eks.command]
}
