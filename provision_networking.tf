# Genie
module "provision_genie" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.genie_cni

  template = file("${path.module}/cluster_configs/genie.tpl.yaml")

  vars = {
    default_plugins = var.calico_cni ? "calico" : ""
  }

  use_system_kubectl = var.use_system_kubectl

  module_depends_on = [module.wait_for_eks.command]
}

# Calico
module "provision_calico" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.calico_cni

  template = file("${path.module}/cluster_configs/calico.tpl.yaml")

  extra_command = var.remove_aws_vpc_cni ? "kubectl --namespace kube-system delete daemonsets aws-node" : ""

  vars = {
    ip_autodetection = var.remove_aws_vpc_cni ? "first-found" : "interface=eth0"
  }

  use_system_kubectl = var.use_system_kubectl

  module_depends_on = var.genie_cni ? [module.provision_genie.apply, module.wait_for_eks.command] : [module.wait_for_eks.command]
}

# aws cni driver
module "provision_aws_cni" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.remove_aws_vpc_cni ? "false" : "true"

  template = file("${path.module}/cluster_configs/aws-node.tpl.yaml")

  vars = {
    externalsnat     = var.calico_cni ? "true" : "false"
    excludesnatcidrs = var.calico_cni ? "192.168.0.0/16" : "false"
  }

  use_system_kubectl = var.use_system_kubectl


  module_depends_on = var.calico_cni ? [module.provision_calico.apply, module.wait_for_eks.command] : [module.wait_for_eks.command]
}

# Set dns to run on aws cni so all containers in calico and aws have dns access
module "provision_dns" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.genie_cni

  template = file("${path.module}/cluster_configs/dns.tpl.yaml")

  vars = {
    cni = var.remove_aws_vpc_cni ? "" : "aws"
  }

  use_system_kubectl = var.use_system_kubectl


  module_depends_on = var.genie_cni ? [module.provision_genie.apply, module.wait_for_eks.command] : [module.wait_for_eks.command]
}
