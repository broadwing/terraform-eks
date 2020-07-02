module "provision_external_dns" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  apply = var.external_dns

  template = file("${path.module}/cluster_configs/external-dns.tpl.yaml")

  vars = {
    domain_filters = length(var.external_dns_domain_filters) > 0 ? "- --domain-filter=${join(
      "\n        - --domain-filter=",
      var.external_dns_domain_filters,
    )}" : ""
    domain_type = var.external_dns_type
    policy_mode = var.external_dns_policy_mode
  }

  module_depends_on = [module.wait_for_eks.command]
}