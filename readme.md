# EKS-Cluster

Broadwing EKS-Cluster module will help with the creation of an EKS cluster using the main EKS module <https://github.com/terraform-aws-modules/terraform-aws-eks>.

Preforms the following:
- Sets up vpc-cni to use prefix delegation to allow more pods and ips per node
- Makes it simpler to created dedicated node groups
- Sets up SSM agent with appopriate IAM roles
- Creates IAM policies for external dns, alb ingress controller, and autoscaling functionality and attaches to created nodes
- Can prefix node names with the cluster name
- Sets appropriate tags for autoscaler and alb controller functionality
- Sets additional lables on nodes

It also provisions the following on the cluster once its up
- ALB ingress controller
- Cluster autoscaler
- Cert manager
- Kubernetes dashboard
- EBS storage for encryption
- External DNS
- FluxCD
- Metrics Server
- Sealed Secrets

The module is built in a way that it simply encriches some of the variables that you would pass into the Community EKS module. This allows you to make any additions or changes that module supports. The decoupling of the modules also makes it easier to upgrade the community module without changing this module.

Previos version of this module wrapped the community module but made it too difficult to keep up with all the changes the community module would make.

## VPC-CNI Prefix Delegation

With `use_vpc_cni_prefix_delegation` enabled the vpc-cni will be setup to allocate `/28` ip addresses on the nodes. Older EKS versions, or when this options is set to false, would attach a single secondary IP to the node. Overall this greatly increases the density of pods on a single node.

For example a `t3.medium` can run `110` pods (memory/cpu permitting) instead of the original `17`. This allows for more traditional clusters that might have a lot of lightweight pods or sidecars running.

The previous generation of this module used calico and cni-genie to increase pod density.


However this means that your EKS cluster will require a lot more IPs from your VPC than before and also means that there needs to be whole `/28` blocks available within your subnet. AWS likes to use random IPs throughout the subnet block so finding free `/28` ranges can be difficult.

For this reason its recommended to create dedicated node subnets (or CIDR Reservations) with large ranges such as:

```
private-eks-pods-subnet-us-east-1a -> 10.0.32.0/19
private-eks-pods-subnet-us-east-1b -> 10.0.64.0/19
private-eks-pods-subnet-us-east-1c`-> 10.0.96.0/19
```

See VPC section for how to create the subnet.

### TODOS:

- Setup OIDC auth by default and use for all provisioned applications
## Example Usage

See [example creation](example/main.tf) for a full example

### Dashboard

After running you can access the dashboard by

1. Retrieving the token from the output `dashboard_token`
2. Running `kubectl proxy`
3. Visiting <http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login> and entering the token from #1


### kubeconfig

Support for managing kubeconfig and its associated local_file resources have been removed; users are able to use the awscli provided `aws eks update-kubeconfig --name <cluster_name> --kubeconfig <cluster_name>.config` to update their local kubeconfig as necessary

### Using dedicated node group

To make a node group dedicated set the `dedicated` value in the node_group map. This will set a taint on the nodes with a value of `dedicated=<node-group-name>:NoSchedule`.

You can then setup pods to run on just that group with

```yml
spec:
  tolerations:
    - key: "dedicated"
      value: broadwing-eks-dedicated
  nodeSelector:
    group-name: broadwing-eks-dedicated
```

### Parts

#### Provider Versions

Setup provider
```hcl
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
```
#### VPC

Create a VPC. If using vpc-cni prefix delgation its recommended to have a big subnet dedicated to nodes, or to use cidr reservations, to allow for more room for /23 ranges within the subnet

```hcl
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
```


#### Providers and Access

Since both our module and the eks module create resources in k8s directly we need to setup their providers

```hcl
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
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
```

#### EKS Data

We'll set the majority of the data in local vars so we can pass to both modules

```hcl

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
```
#### Enrichment module

Pass the data to the enrichment module to setup vars and provision resources

```hcl
module "broadwing_eks_enrichment" {
  source = "../terraform-eks"

  cluster_name           = local.cluster_name
  eks_module             = module.eks
  eks_module_cluster_arn = module.eks.cluster_arn

  self_managed_node_group_defaults = local.self_managed_node_group_defaults
  self_managed_node_groups         = local.self_managed_node_groups

  eks_managed_node_group_defaults = local.eks_managed_node_group_defaults
  eks_managed_node_groups         = local.eks_managed_node_groups
}
```

#### EKS Module

Finally call the community EKS module with outputs from the enrichment module

```hcl
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
```

### Optional Changes
#### Per AZ ASG

If you want an ASG to be created per AZ you can do so with a node_groups definition like:

```hcl
self_managed_node_groups = [
    for subnet in  aws_subnet.node_subnets[*].id :
    {
      name          = "base-${subnet}"
      instance_type = "m5.xlarge"
      subnet_ids    = [subnet]
    }
  ]
```

In this case one ASG will be created per AZ. All ASGs will have a launch config with the same "groupName" label. The cluster auto scaler can then scale each ASG and AZ individually. This is helpful when relying on EBS volume claims that could be tied to a specific AZ.

#### EKS Configurations

Lots of other options can be seen on the EKS example page https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples
