locals {
  external_dns_domain_filters = length(var.external_dns_domain_filters) > 0 ? "- --domain-filter=${join(
    "\n        - --domain-filter=",
    var.external_dns_domain_filters,
  )}" : ""
}

data "kubectl_path_documents" "external_dns_resources" {
  count = var.provision_external_dns ? 1 : 0

  pattern = "${path.module}/cluster_configs/external-dns.tpl.yaml"
  vars = {
    domain_filters = local.external_dns_domain_filters
    domain_type    = var.external_dns_type
    txt_owner_id   = "eks-${var.cluster_name}-external-dns"
    region         = data.aws_region.current.name
  }
}

resource "kubectl_manifest" "external_dns_resources" {
  count = var.provision_external_dns ? length(data.kubectl_path_documents.external_dns_resources[0].documents) : 0

  yaml_body = element(data.kubectl_path_documents.external_dns_resources[0].documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [var.eks_module_cluster_id]
}
