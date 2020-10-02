# EKS-Cluster

Core functionality is a wrapper around <https://github.com/terraform-aws-modules/terraform-aws-eks> to make it easier to use.

In addition we preform some provisioning steps on the cluster itself, such as adding calico CNI Driver and set it up to work with the VPC CNI Driver, installing the dashboard, installing the alb and dns controller, and updating the EBS Storage Driver.

Some variables and options that are available on the `terraform-aws-eks` module are purposely not exposed here so its simpler and more in-line with how our components can use it.

If in the future additional features are need we can map variables from this module to the wrapped open source one.

## Example Usage
```hcl
locals {
  node_groups = [
    {
      name          = "base"
      min_count     = 1
      count         = 2
      max_count     = 2
      instance_type = "m5.xlarge"
      dedicated     = false
      autoscale     = true
      gpu           = false
      external_lb   = true
    }
  ]

  users = [
    {
      userarn  = "arn:aws:iam::<account_id>:user/<user>"
      username = "<user>"
      group    = "system:masters"
    }
  ]
}

module "eks" {
  source = "git@github.com:broadwing/terraform-eks.git"

  name        = "main"
  environment = "prod"

  cluster_version = "1.17"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  nodes_additional_security_group_ids = [module.vpc.default_security_group_id]

  aws_profile = "default"

  external_dns_domain_filters = ["<route 53 domain>"]
  external_dns_type = "<internal|external>" or "" for auto-detect (default)

  nodes_key_name = "eks"

  node_groups = local.node_groups

  alb_prefix                   = "k8s"
  alb_ingress_controller_image = "docker.io/m00nf1sh/aws-alb-ingress-controller:v1.2.0-alpha.2" # New ingress controller with shared alb support
  get_dashboard_token          = "false"

  map_users = local.users
}
```

### Per AZ ASG

If you want an ASG to be created per AZ you can do so with a node_groups definition like:

```hcl
node_groups = [
    for subnet in module.vpc.private_subnets :
    {
      name          = "base"
      instance_type = "m5.xlarge"
      subnets       = [subnet]
    }
  ]
```

In this case one ASG will be created per AZ. All ASGs will have a launch config with the same "groupName" label. The cluster auto scaler can then scale each ASG and AZ individually. This is helpful when relying on EBS volume claims that could be tied to a specific AZ.

### Spot Worker Groups

If you want to create a worker group that utilizes Spot instances you can do so with a node_groups definition like:

```hcl
node_groups = [
  {
    name          = "base-spot"
    lifecycle     = "spot"
    instance_type = "m5.xlarge"
  }
]
```

This will create a new Launch Template backed ASG using Spot instances and append the `node.kubernetes.io/lifecycle=spot` label to these nodes.

## Dashboard

After running you can access the dashboard by

1. Retrieving the token from the output `dashboard_token`
2. Running `kubectl proxy`
3. Visiting <http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login> and entering the token from #1

## VPC AWS CNI

Note because we use `calico` if a service needs to be accessible by the control plane (such as dashboard, ability to use `kubectl proxy`, or admission controllers) make sure the service is setup to use the `aws` cni

For example the dashboard will have:

```yaml
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
      annotations:
        cni: "aws"
```
