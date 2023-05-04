
## See vpc.tf for vpc creation example
## See versions.tf and providers.tf for provider setup example

################################################################################
# EKS Data
################################################################################
locals {
  cluster_name    = "broadwing-eks"
  cluster_version = "1.23"

  self_managed_node_group_defaults = {
    instance_type          = "t3.medium"
    key_name               = "eks"
    vpc_security_group_ids = [module.vpc.default_security_group_id]
  }

  eks_managed_node_group_defaults = {
    instance_type          = "t3.medium"
    key_name               = "eks"
    vpc_security_group_ids = [module.vpc.default_security_group_id]
  }

  self_managed_node_groups = {
    base = {
      max_size     = 2
      desired_size = 1
    }
    dedicated = {
      min_size                             = 0
      max_size                             = 2
      desired_size                         = 1
      dedicated                            = true
      exclude_from_external_load_balancers = true
    }
  }

  eks_managed_node_groups = {
    eks-mngd = {
      max_size                             = 2
      dedicated                            = true
      exclude_from_external_load_balancers = true
      iam_role_use_name_prefix             = false
    }
  }

  aws_auth_users = [
    {
      userarn  = data.aws_caller_identity.current.arn
      username = data.aws_caller_identity.current.user_id
      groups   = ["system:masters"]
    }
  ]
}

################################################################################
# Enrichment Module
################################################################################

module "broadwing_eks_enrichment" {
  source = "github.com/broadwing/terraform-eks.git?ref=v2.0.0"

  cluster_name           = local.cluster_name
  eks_module             = module.eks
  eks_module_cluster_arn = module.eks.cluster_arn

  self_managed_node_group_defaults = local.self_managed_node_group_defaults
  self_managed_node_groups         = local.self_managed_node_groups

  eks_managed_node_group_defaults = local.eks_managed_node_group_defaults
  eks_managed_node_groups         = local.eks_managed_node_groups


}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.13"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  cluster_endpoint_public_access = true

  vpc_id = module.vpc.vpc_id

  control_plane_subnet_ids = module.vpc.private_subnets
  subnet_ids               = aws_subnet.node_subnets[*].id

  node_security_group_additional_rules = module.broadwing_eks_enrichment.enriched_node_security_group_additional_rules

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = module.broadwing_eks_enrichment.enriched_self_managed_node_group_defaults
  self_managed_node_groups         = module.broadwing_eks_enrichment.enriched_self_managed_node_groups

  # EKS Manged Node Groups
  eks_managed_node_group_defaults = module.broadwing_eks_enrichment.enriched_eks_managed_node_group_defaults
  eks_managed_node_groups         = module.broadwing_eks_enrichment.enriched_eks_managed_node_groups

  # aws-auth configmap
  # Only create if we dont have a managed instance group.
  # Since we created a managed group AWS will automatically create the config map
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = true

  aws_auth_users = local.aws_auth_users

  tags = {
    Terraform = "true"
  }
}
