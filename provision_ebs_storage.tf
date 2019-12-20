# ebs-storage
module "provision_ebs" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  template = file("${path.module}/cluster_configs/ebs-storage-class.tpl.yaml")

  extra_command = "kubectl --namespace kube-system delete storageclasses.storage.k8s.io gp2"

  vars = {
    wait_for_eks = null_resource.wait_for_eks.id
    encrypted    = var.ebs_default_encrypted
  }
}
