# Genie
module "provision_genie" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.genie_cni

  template = file("${path.module}/cluster_configs/genie.tpl.yaml")

  vars = {
    wait_for_eks = module.wait_for_eks.command_id
    default_plugins = var.calico_cni ? "calico" : ""
  }
}

# Calico
module "provision_calico" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.calico_cni

  template = file("${path.module}/cluster_configs/calico.tpl.yaml")

  extra_command = var.remove_aws_vpc_cni ? "--namespace kube-system delete daemonsets aws-node" : ""

  vars = {
    wait_for_genie   = var.genie_cni ? module.provision_genie.md5 : ""
    wait_for_eks     = module.wait_for_eks.command_id
    ip_autodetection = var.remove_aws_vpc_cni ? "first-found" : "interface=eth0"
  }
}

# aws cni driver
module "provision_aws_cni" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.remove_aws_vpc_cni ? "false" : "true"

  template = file("${path.module}/cluster_configs/aws-node.tpl.yaml")

  vars = {
    wait_for_calico = var.calico_cni ? module.provision_calico.md5 : ""
    wait_for_eks    = module.wait_for_eks.command_id
    externalsnat    = var.calico_cni ? "true" : "false"
  }
}

# Set dns to run on aws cni so all containers in calico and aws have dns access
module "provision_dns" {
  source     = "./modules/kubectl-apply"
  kubeconfig = "${path.root}/${var.name}.kubeconfig"

  apply = var.genie_cni

  template = file("${path.module}/cluster_configs/dns.tpl.yaml")

  vars = {
    wait_for_genie  = var.genie_cni ? module.provision_genie.md5 : ""
    wait_for_eks    = module.wait_for_eks.command_id
    cni             = var.remove_aws_vpc_cni ? "" : "aws"
  }
}
