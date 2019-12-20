variable "name" {
  description = "Name of cluster"
}

variable "cluster_version" {
  description = "Version of the cluster"
  default     = "1.13"
}

variable "environment" {
  description = "Name of the environment"
}

variable "vpc_id" {
  description = "Id of VPC"
}

variable "subnets" {
  description = "Subnets to place master nodes in"
  type        = list(string)
}

variable "aws_profile" {
  description = "AWS Profile to use for kubectl commands"
}

variable "genie_cni" {
  description = "Install Genie CNI"
  default     = "true"
}

variable "calico_cni" {
  description = "Install Calico CNI"
  default     = "true"
}

variable "remove_aws_vpc_cni" {
  description = "Remove AWS VPC CNI after installing calico"
  default     = "false"
}

variable "dashboard" {
  description = "If dashboard should be deployed"
  default     = "true"
}

variable "get_dashboard_token" {
  description = "If dashboard token should be retrieved"
  default     = "true"
}

variable "alb_ingress_controller" {
  description = "If alb ingress controller should be installed"
  default     = "true"
}

variable "external_dns" {
  description = "If external dns controller should be installed"
  default     = "true"
}

variable "metrics_server" {
  description = "If metrics-server should be installed"
  default     = "true"
}

variable "external_dns_domain_filters" {
  description = "Domains to pass in to External DNS --domain-filter option"
  default     = []
  type        = list(string)
}

variable "allow_ssh" {
  description = "If SSH should be allowed into the worker nodes security group"
  default     = "true"
}

variable "allow_ssh_cidr" {
  description = "If allow_ssh is enabled which ips can access port 22"
  default     = "10.0.0.0/8"
}

variable "nodes_key_name" {
  description = "SSH Key to use for nodes"
}


variable "nodes_additional_security_group_ids" {
  description = "additional security groups ids to attach to nodes"
  type        = list(string)
  default     = []
}

variable "nodes_ami_id" {
  description = "The AMI ID to use. If empty looks up from AWS EKS provided one"
  default     = ""
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap. See examples/eks_test_fixture/variables.tf for example format."
  type        = list(string)
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/eks_test_fixture/variables.tf for example format."
  type        = list(map(string))
  default     = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap. See examples/eks_test_fixture/variables.tf for example format."
  type        = list(map(string))
  default     = []
}


variable "ebs_default_encrypted" {
  description = "If we should enable EBS encryption by default for k8s created volumes"
  default     = "true"
}

variable "alb_prefix" {
  description = "A Prefix to add to any ALBs or Target Groups the ALB Ingress Controller Creates"
  default     = ""
}

variable "alb_ingress_controller_image" {
  description = "Image for installing ingress controller"
  default     = "894847497797.dkr.ecr.us-west-2.amazonaws.com/aws-alb-ingress-controller:v1.0.0"
}

variable "sealed_secrets_controller" {
  description = "Whether or not to install the sealed secrests controller"
  default     = "true"
}

variable "node_groups" {
  type = list(object({
    name          = string
    min_count     = number
    count         = number
    max_count     = number
    instance_type = string
    dedicated     = bool
    autoscale     = bool
    gpu           = bool
    external_lb   = bool
  }))
}
