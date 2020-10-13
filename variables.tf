variable "name" {
  description = "Name of cluster"
}

variable "cluster_version" {
  description = "Version of the cluster"
  default     = "1.17"
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
  description = "AWS Profile to use when generating kubeconfig"
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
  default     = true
  type        = bool
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

variable "external_dns_type" {
  description = "The Route53 zone type you are editing with External DNS --domain-type option"
  default     = ""
}

variable "external_policy_mode" {
  description = "The External DNS policy mode to pass to External DNS --policy option"
  default     = "upsert-only"
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
  description = "Additional AWS account numbers to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type        = list(string)
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
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
  default     = "docker.io/amazon/aws-alb-ingress-controller:v1.1.7"
}

variable "sealed_secrets_controller" {
  description = "Whether or not to install the sealed secrests controller"
  default     = "true"
}

variable "node_groups" {
  type        = list(any)
  description = "The node groups to create. See `node_group_defaults` for possible options"
}

variable "node_group_defaults" {
  type = object({
    name                                     = string
    lifecycle                                = string
    min_count                                = number
    count                                    = number
    max_count                                = number
    instance_type                            = string
    dedicated                                = bool
    autoscale                                = bool
    gpu                                      = bool
    external_lb                              = bool
    subnets                                  = list(string)
    override_instance_types                  = list(string)
    spot_instance_pools                      = number
    on_demand_base_capacity                  = number
    on_demand_percentage_above_base_capacity = number
  })
  default = {
    name                                     = null        # Name of the node group
    lifecycle                                = "ondemand"  # Lifecycle of node (ondemand or spot)
    min_count                                = 1           # Min count for ASG
    count                                    = 2           # Initial desired count for ASG
    max_count                                = 2           # Max count for ASG
    instance_type                            = "m5.xlarge" # Instance type
    dedicated                                = false       # If true taint will be applied to group to make it a dedicated node group.
    autoscale                                = true        # If cluster autoscaling should control desired count
    gpu                                      = false       # If GPU instance types should be used
    external_lb                              = true        # If ALB External LB should use these nodes for attaching to target group
    subnets                                  = null        # If set, a specific set of subnets to use for this ASG. Helpful when creating one ASG/Node Group per AZ. Defaults to var.subnets
    override_instance_types                  = null        # A list of override instance types for mixed ondemand/spot instances policy
    spot_instance_pools                      = 10          # Number of Spot pools per availability zone to allocate capacity. EC2 Auto Scaling selects the cheapest Spot pools and evenly allocates Spot capacity across the number of Spot pools that you specify.
    on_demand_base_capacity                  = 0           # Absolute minimum amount of desired capacity that must be fulfilled by on-demand instances
    on_demand_percentage_above_base_capacity = 0           # Percentage split between on-demand and Spot instances above the base on-demand capacity
  }
}

variable managed_node_groups {
  type        = list(any)
  description = "The Managed Node groups to create. See `node_group_defaults` for possible options"
  default     = []
}

variable "managed_node_group_defaults" {
  type = object({
    name              = string
    min_count         = number
    count             = number
    max_count         = number
    instance_type     = string
    dedicated         = bool
    autoscale         = bool
    external_lb       = bool
    subnets           = list(string)
    disk_size         = number
    additional_labels = map(string)
  })
  default = {
    name              = null        # Name of the node group
    min_count         = 1           # Min count for ASG
    count             = 2           # Initial desired count for ASG
    max_count         = 2           # Max count for ASG
    instance_type     = "m5.xlarge" # Instance type
    dedicated         = false       # If true taint will be applied to group to make it a dedicated node group.
    autoscale         = true        # If cluster autoscaling should control desired count
    external_lb       = true        # If ALB External LB should use these nodes for attaching to target group
    subnets           = null        # If set, a specific set of subnets to use for this ASG. Helpful when creating one ASG/Node Group per AZ. Defaults to var.subnets
    disk_size         = 100         # Defaults to 100gb, same as worker node groups
    additional_labels = {}          # Any additional labels to add
  }
}


variable "pre_userdata" {
  description = "Userdata to pre-append to the default userdata."
  default     = ""
}

variable "enable_irsa" {
  description = "Whether to create OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = false
}

variable "flux" {
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
  default     = null
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
