locals {
  coredns_addon = var.coredns_addon ? {
    coredns = {
      enabled = true
    }
  } : {}

  kube_proxy_addon = var.kube_proxy_addon ? {
    kube-proxy = {
      enabled = true
    }
  } : {}

  vpc_cni_addon = var.vpc_cni_addon ? {
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      configuration_values = var.use_vpc_cni_prefix_delegation ? jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_IP_TARGET           = "5"
          MINIMUM_IP_TARGET        = "2"
        }
      }) : null
    }
  } : {}

  enriched_cluster_addons = merge(
    local.coredns_addon,
    local.kube_proxy_addon,
    local.vpc_cni_addon,
    var.cluster_addons
  )
}
