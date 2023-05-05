locals {
  ################################################################################
  # Node Group Defaults
  ################################################################################

  enriched_self_managed_node_group_defaults = merge(
    # Merge original data
    var.self_managed_node_group_defaults,
    {
      # Additional roles policies
      iam_role_additional_policies = {
        "AmazonEC2RoleforSSM"          = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
        "AmazonSSMManagedInstanceCore" = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "eks_workers_albs"             = aws_iam_policy.eks_workers_albs.arn,
        "eks_workers_route53"          = aws_iam_policy.eks_workers_route53.arn,
        "worker_autoscaling"           = aws_iam_policy.worker_autoscaling.arn,
      }

      autoscaling_group_tags = merge(
        try(var.self_managed_node_group_defaults.autoscaling_group_tags, {}),
      )
    },
  )

  enriched_eks_managed_node_group_defaults = merge(
    # Merge original data
    var.eks_managed_node_group_defaults,
    {
      # Additional roles policies
      iam_role_additional_policies = {
        "AmazonEC2RoleforSSM"          = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
        "AmazonSSMManagedInstanceCore" = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "eks_workers_albs"             = aws_iam_policy.eks_workers_albs.arn,
        "eks_workers_route53"          = aws_iam_policy.eks_workers_route53.arn,
        "worker_autoscaling"           = aws_iam_policy.worker_autoscaling.arn,
      }

      launch_template_tags = merge(
        try(var.self_managed_node_group_defaults.launch_template_tags, {}),
      )
    },
  )

  ################################################################################
  # Additional node group security groups
  ################################################################################
  # There are now no additional rules this module needs to add but will keep this
  # in case we need to add any in the future
  node_security_group_additional_rules = var.node_security_group_additional_rules

  ################################################################################
  # Prefixed Names
  ################################################################################

  enriched_self_managed_node_group_prefixed_names = {
    for key, node in var.self_managed_node_groups :
    key =>
    # If name is set use that
    try(
      var.prefix_names_with_cluster ? "${var.cluster_name}-${node.name}" : node.name,
      var.prefix_names_with_cluster ? "${var.cluster_name}-${key}" : key
    )
  }

  enriched_eks_managed_node_group_prefixed_names = {
    for key, node in var.eks_managed_node_groups :
    key =>
    # If name is set use that
    try(
      var.prefix_names_with_cluster ? "${var.cluster_name}-${node.name}" : node.name,
      var.prefix_names_with_cluster ? "${var.cluster_name}-${key}" : key
    )
  }

  ################################################################################
  # Self Managed Node Groups
  ################################################################################
  enriched_self_managed_node_groups = {
    for key, node in var.self_managed_node_groups :

    # Merge original node values
    local.enriched_self_managed_node_group_prefixed_names[key] => merge(node, {
      # Set prefixed name if needed
      name = local.enriched_self_managed_node_group_prefixed_names[key]

      # Merge tags
      tags = merge(try(local.enriched_self_managed_node_group_prefixed_names.tags, {}), try(node.tags, {}),
        # Base tags
        {
          group-name                                                = local.enriched_self_managed_node_group_prefixed_names[key]
          "node.kubernetes.io/exclude-from-external-load-balancers" = try(node.exclude_from_external_load_balancers, local.enriched_self_managed_node_group_defaults.exclude_from_external_load_balancers, false) ? "true" : "false"
        },

        # Autoscaling tags
        try(node.autoscale, local.enriched_self_managed_node_group_defaults.autoscale, var.default_autoscale) ? {
          "k8s.io/cluster-autoscaler/enabled"                        = "true"
          "k8s.io/cluster-autoscaler/${var.cluster_name}"            = "owned"
          "k8s.io/cluster-autoscaler/node-template/label/group-name" = local.enriched_self_managed_node_group_prefixed_names[key]
        } : {},

        # Autoscaling taint tag
        try(node.autoscale, local.enriched_self_managed_node_group_defaults.autoscale, var.default_autoscale)
        &&
        try(node.dedicated, local.enriched_self_managed_node_group_defaults.dedicated, false) ? {
          "k8s.io/cluster-autoscaler/node-template/taint/dedicated" = "${local.enriched_self_managed_node_group_prefixed_names[key]}:NoSchedule"
        } : {}
      )


      bootstrap_extra_args = replace(
        <<-EOT
        --kubelet-extra-args "

        --node-labels=group-name=${local.enriched_self_managed_node_group_prefixed_names[key]},
        ${try(node.exclude_from_external_load_balancers, local.enriched_self_managed_node_group_defaults.exclude_from_external_load_balancers, false) ? "node.kubernetes.io/exclude-from-external-load-balancers=true," : ""}
        instanceId=$(ec2-metadata -i | cut -d ' ' -f2)

        ${try(node.dedicated, local.enriched_self_managed_node_group_defaults.dedicated, false) ? " --register-with-taints=dedicated=${local.enriched_self_managed_node_group_prefixed_names[key]}:NoSchedule" : ""}

        ${var.use_vpc_cni_prefix_delegation ? " --max-pods=$(/etc/eks/max-pods-calculator.sh --instance-type-from-imds --cni-version 1.11.4 --cni-prefix-delegation-enabled)" : ""}
        "
        EOT
      , "\n", "")
    })
  }

  ################################################################################
  # EKS Managed Node Groups
  ################################################################################
  enriched_eks_managed_node_groups = {
    for key, node in var.eks_managed_node_groups :

    # Merge original node values
    local.enriched_eks_managed_node_group_prefixed_names[key] => merge(node, {
      # Set prefixed name if needed
      name = local.enriched_eks_managed_node_group_prefixed_names[key]

      # Merge tags
      tags = merge(try(local.enriched_eks_managed_node_group_prefixed_names.tags, {}), try(node.tags, {}),
        # Base tags
        {
          group-name                                                = local.enriched_eks_managed_node_group_prefixed_names[key]
          "node.kubernetes.io/exclude-from-external-load-balancers" = try(node.exclude_from_external_load_balancers, local.enriched_eks_managed_node_group_defaults.exclude_from_external_load_balancers, false) ? "true" : "false"
        },

        # Autoscaling tags
        try(node.autoscale, local.enriched_eks_managed_node_group_defaults.autoscale, var.default_autoscale) ? {
          "k8s.io/cluster-autoscaler/enabled"                        = "true"
          "k8s.io/cluster-autoscaler/${var.cluster_name}"            = "owned"
          "k8s.io/cluster-autoscaler/node-template/label/group-name" = local.enriched_eks_managed_node_group_prefixed_names[key]
        } : {},

        # Autoscaling taint tag
        try(node.autoscale, local.enriched_eks_managed_node_group_defaults.autoscale, var.default_autoscale)
        &&
        try(node.dedicated, local.enriched_eks_managed_node_group_defaults.dedicated, false) ? {
          "k8s.io/cluster-autoscaler/node-template/taint/dedicated" = "${local.enriched_eks_managed_node_group_prefixed_names[key]}:NoSchedule"
        } : {}
      )

      # See issue https://github.com/awslabs/amazon-eks-ami/issues/844
      # https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2150
      pre_bootstrap_user_data = <<-EOT
        #!/bin/bash
        set -ex
        cat <<-EOF > /etc/profile.d/bootstrap.sh

        export KUBELET_EXTRA_ARGS="${replace(
      <<-EOS
        --node-labels=${try(node.exclude_from_external_load_balancers, local.enriched_eks_managed_node_group_defaults.exclude_from_external_load_balancers, false) ? "node.kubernetes.io/exclude-from-external-load-balancers=true," : ""}
        instanceId=$(ec2-metadata -i | cut -d ' ' -f2)

        ${var.use_vpc_cni_prefix_delegation ? " --max-pods=$(/etc/eks/max-pods-calculator.sh --instance-type-from-imds --cni-version 1.11.4 --cni-prefix-delegation-enabled)" : ""}
        EOS
    , "\n", "")}"
        EOF

        # Source extra environment variables in bootstrap script
        sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
        sed -i 's/KUBELET_EXTRA_ARGS=$2/KUBELET_EXTRA_ARGS="$2 $KUBELET_EXTRA_ARGS"/' /etc/eks/bootstrap.sh
    EOT


    labels = merge(
      try(local.enriched_eks_managed_node_group_defaults.labels, {}),
      try(node.labels, {}),
      {
        group-name = local.enriched_eks_managed_node_group_prefixed_names[key]
      }
    )

    taints = merge(
      try(local.enriched_eks_managed_node_group_defaults.taints, {}),
      try(node.taints, {}),
      try(node.dedicated, local.enriched_eks_managed_node_group_defaults.dedicated, false) ?
      {
        dedicated = {
          key    = "dedicated"
          value  = local.enriched_eks_managed_node_group_prefixed_names[key]
          effect = "NO_SCHEDULE"
        }
      } : {}
    )
})
}
}
