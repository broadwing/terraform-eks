terraform {
  required_version = ">= 1"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

################################################################################
# Create VPC
################################################################################
# With vpc-cni using prefix delgation its recommended to have a big subnet
# dedicated to nodes, or to use cidr reservations, to allow for more room for /23 ranges within the subnet
locals {
  node_subnets = ["10.0.32.0/19", "10.0.64.0/19", "10.0.96.0/19"]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.4.0/23", "10.0.6.0/23", "10.0.8.0/23"]

  enable_nat_gateway = true
}

resource "aws_subnet" "node_subnets" {
  count = length(local.node_subnets)

  vpc_id                          = module.vpc.vpc_id
  cidr_block                      = local.node_subnets[count.index]
  availability_zone               = length(regexall("^[a-z]{2}-", element(module.vpc.azs, count.index))) > 0 ? element(module.vpc.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(module.vpc.azs, count.index))) == 0 ? element(module.vpc.azs, count.index) : null
  assign_ipv6_address_on_creation = false

  tags = merge(
    {
      "Name" = format("${module.vpc.name}-nodes-%s", element(module.vpc.azs, count.index))
    }
  )
}

resource "aws_route_table_association" "node_subnets" {
  count = length(local.node_subnets)

  subnet_id      = element(aws_subnet.node_subnets[*].id, count.index)
  route_table_id = element(module.vpc.private_route_table_ids, count.index)
}

################################################################################
# Setup Providers
################################################################################
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

################################################################################
# EKS Data
################################################################################

locals {
  cluster_name    = "broadwing-eks"
  cluster_version = "1.22"

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

  cluster_name          = local.cluster_name
  eks_module            = module.eks
  eks_module_cluster_id = module.eks.cluster_id

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
  version = "~> 18.0"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  vpc_id = module.vpc.vpc_id

  control_plane_subnet_ids = module.vpc.private_subnets
  subnet_ids               = aws_subnet.node_subnets[*].id

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
