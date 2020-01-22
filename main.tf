locals {
  kubeconfig_path = abspath(local_file.kubeconfig.filename)
}

data "aws_caller_identity" "current" {
}

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }

  most_recent = true

  # Owner ID of AWS EKS team
  owners = ["602401143452"]
}

data "aws_ami" "eks_gpu_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-gpu-node-${var.cluster_version}-v*"]
  }

  most_recent = true

  # Owner ID of AWS EKS team
  owners = ["602401143452"]
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  version = "5.0.0"

  cluster_name    = var.name
  cluster_version = var.cluster_version

  vpc_id  = var.vpc_id
  subnets = var.subnets

  #We need to manage auth ourselves since we create the workers later their role wont be added
  manage_aws_auth = "false"

  write_kubeconfig      = "false"
  write_aws_auth_config = "false"

  kubeconfig_aws_authenticator_env_variables = {
    AWS_PROFILE = var.aws_profile
  }

  worker_additional_security_group_ids = var.nodes_additional_security_group_ids

  # This will launch an autoscaling group with only On-Demand instances
  worker_groups = [
    for wg in var.node_groups:
    {
      # Worker group specific values
      name                 = wg.name
      instance_type        = wg.instance_type
      asg_min_size         = wg.min_count
      asg_desired_capacity = wg.count
      asg_max_size         = wg.max_count
      kubelet_extra_args   = replace(
                              <<-EOT
                                --node-labels=groupName=${wg.name},${wg.external_lb ? "" : "alpha.service-controller.kubernetes.io/exclude-balancer=true,"}instanceId='$(curl http://169.254.169.254/latest/meta-data/instance-id)'
                                ${wg.dedicated ? " --register-with-taints=dedicated=${wg.name}:NoSchedule" : ""}
                                --eviction-hard="memory.available<5%"
                                --eviction-soft="memory.available<10%"
                                --eviction-soft-grace-period="memory.available=5m"
                                --system-reserved="memory=500Mi"
                              EOT
                              , "\n", " ")
      autoscaling_enabled  = wg.autoscale

      tags = slice([
        {
          key                 = "groupName"
          value               = wg.name
          propagate_at_launch = true
        },
        {
          key                 = "alpha.service-controller.kubernetes.io/exclude-balancer"
          value               = wg.external_lb ? "false" : "true"
          propagate_at_launch = true
        },
        {
          key                  = "k8s.io/cluster-autoscaler/node-template/label"
          value                = wg.name
          propagate_at_launch  = true
        },
        {
          key                  = "k8s.io/cluster-autoscaler/node-template/taint/dedicated"
          value                = "${wg.name}:NoSchedule"
          propagate_at_launch  = true
        }
      ], 0, wg.dedicated ? 4 : 3)

      # Vars for all worker groups
      key_name             = var.nodes_key_name
      pre_userdata         = templatefile("${path.module}/workers_user_data.sh.tpl", {pre_userdata = var.pre_userdata})
      ami_id               = var.nodes_ami_id == "" ? ( wg.gpu ? data.aws_ami.eks_gpu_worker.id : data.aws_ami.eks_worker.id ) : var.nodes_ami_id
      termination_policies = ["OldestLaunchConfiguration", "Default"]

      enabled_metrics = [
        "GroupDesiredCapacity",
        "GroupInServiceInstances",
        "GroupMaxSize",
        "GroupMinSize",
        "GroupPendingInstances",
        "GroupStandbyInstances",
        "GroupTerminatingInstances",
        "GroupTotalInstances",
      ]
    }
  ]

  cluster_enabled_log_types = ["api","audit","authenticator","controllerManager","scheduler"]

  tags = {
    Owner       = "Terraform"
    Environment = var.environment
  }
}

resource "local_file" "kubeconfig" {
  content_base64 = base64encode(module.eks.kubeconfig)
  filename       = abspath("${path.root}/${var.name}.kubeconfig")

  file_permission = "0644"
}

module "wait_for_eks" {
  source     = "./modules/kubectl-apply"
  kubeconfig = abspath(local_file.kubeconfig.filename)

  extra_command = <<-EOT
    until kubectl version
    do
      echo "Waiting for cluster"
      sleep 10
    done
  EOT
}
