variable "cluster_name" {
  description = "Name of the EKS cluster. Must match the cluster_name passed into the eks module"
  type        = string
}

variable "eks_module" {
  description = "A reference to the whole eks module. eg eks_module = module.eks"
  type        = any
}

variable "eks_module_cluster_arn" {
  description = "Output of the eks module's cluster_arn for enforcing dependency order. eg eks_module_cluster_arn = module.eks.cluster_arn"
  type        = string
}

################################################################################
# Helper functions that this module exposes to make changes on upstream EKS module more simple
################################################################################
variable "prefix_names_with_cluster" {
  description = "If the names of nodes and their resources should be prefixed with the EKS name"
  type        = bool
  default     = true
}

variable "default_autoscale" {
  description = "If appropriate autoscaling tags should be added to resources. Can be overriden by `autoscale` value in each nodegroup"
  type        = bool
  default     = true
}

variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source"
  type        = any
  default     = {}
}

################################################################################
# EKS Addons
################################################################################

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster. This module will merge in some default addons"
  type        = any
  default     = {}
}

variable "kube_proxy_addon" {
  description = "If the kube-proxy addon should be enabled"
  type        = bool
  default     = true
}

variable "coredns_addon" {
  description = "If the coredns addon should be enabled"
  type        = bool
  default     = true
}

variable "vpc_cni_addon" {
  description = "If the vpc-cni addon should be enabled"
  type        = bool
  default     = true
}

variable "use_vpc_cni_prefix_delegation" {
  description = "Sets ENABLE_PREFIX_DELEGATION, WARM_IP_TARGET, and MINIMUM_IP_TARGET on the vpc-cni to enable more pods and ips per node"
  type        = bool
  default     = true
}

################################################################################
# Self Managed Node Group
################################################################################

variable "self_managed_node_groups" {
  description = "Map of self-managed node group definitions that this module will add customatizations to that can then be past into the EKS module"
  type        = any
  default     = {}
}

variable "self_managed_node_group_defaults" {
  description = "Map of self-managed node group default configurations that this module will add customatizations to that can then be past into the EKS module"
  type        = any
  default     = {}
}

################################################################################
# EKS Managed Node Group
################################################################################

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions that this module will add customatizations to that can then be past into the EKS module"
  type        = any
  default     = {}
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations that this module will add customatizations to that can then be past into the EKS module"
  type        = any
  default     = {}
}

################################################################################
# ALB Ingress Controller
################################################################################
variable "provision_aws_load_balancer_controller" {
  description = "If alb ingress controller should be installed"
  default     = true
  type        = bool
}

variable "aws_load_balancer_controller_image" {
  description = "Image for installing ingress controller"
  default     = "public.ecr.aws/eks/aws-load-balancer-controller:v2.5.3"
}

################################################################################
# Cluster Autoscaler
################################################################################
variable "provision_cluster_autoscaler" {
  description = "If cluster autoscaler should be installed"
  default     = true
  type        = bool
}

################################################################################
# Cert Manager
################################################################################
variable "provision_cert_manager" {
  description = "If cert-manager should be installed"
  default     = true
  type        = bool
}

################################################################################
# Dashboard
################################################################################
variable "provision_dashboard" {
  description = "If dashboard should be deployed"
  default     = true
  type        = bool
}

variable "get_dashboard_token" {
  description = "If dashboard token should be retrieved"
  default     = true
  type        = bool
}

################################################################################
# EBS Storage
################################################################################
variable "provision_ebs_storage" {
  description = "If ebs storage should be deployed to control encryption settings"
  default     = true
  type        = bool
}

variable "ebs_default_encrypted" {
  description = "If we should enable EBS encryption by default for k8s created volumes"
  default     = true
  type        = bool
}

################################################################################
# External DNS
################################################################################
variable "provision_external_dns" {
  description = "If external dns controller should be installed"
  default     = true
  type        = bool
}

variable "external_dns_domain_filters" {
  description = "Domains to pass in to External DNS --domain-filter option"
  default     = []
  type        = list(string)
}

variable "external_dns_type" {
  description = "The Route53 zone type you are editing with External DNS --domain-type option"
  default     = ""
}

variable "external_dns_policy" {
  description = "The --policy type to pass to external-dns. By default upsert-only would prevent ExternalDNS from deleting any records."
  default     = "upsert-only"
}

################################################################################
# Flux
################################################################################
variable "provision_flux" {
  type        = bool
  default     = false
  description = "If Flux should be deployed"
}

variable "flux_git_user" {
  type        = string
  default     = "flux"
  description = "The flux git-user"
}

variable "flux_git_url" {
  type        = string
  default     = ""
  description = "The flux git-url to track"
}

variable "flux_git_path" {
  type        = string
  default     = "namespaces,workloads"
  description = "The flux git-path to use"
}

variable "flux_git_branch" {
  type        = string
  default     = "master"
  description = "The flux git-branch to use"
}

variable "flux_manifest_generation" {
  type        = bool
  default     = false
  description = "If flue manifest-generation should be true or false (for kustomize support)"
}

################################################################################
# Metrics Server
################################################################################
variable "provision_metrics_server" {
  description = "If metrics-server should be installed"
  default     = true
  type        = bool
}

################################################################################
# Metrics Server
################################################################################
variable "provision_sealed_secrets_controller" {
  description = "Whether or not to install the sealed secrests controller"
  default     = true
  type        = bool
}
