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
