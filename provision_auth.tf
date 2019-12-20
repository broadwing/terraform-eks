# Auth
# We'll provision auth ourselves so that worker nodes can't join until we are finished provisioing the cluster and networking
module "provision_auth_config" {
  source     = "./modules/kubectl-apply"
  kubeconfig = local.kubeconfig_path

  template = file(
    "${path.module}/cluster_configs/auth/config-map-aws-auth.yaml.tpl",
  )

  vars = {
    wait_for_eks = module.wait_for_eks.command_id
    calico_cni   = module.provision_calico.md5
    worker_role_arn = join(
      "",
      data.template_file.launch_template_worker_role_arns.*.rendered,
    )
    map_users    = join("\n", data.template_file.map_users.*.rendered)
    map_roles    = join("\n", data.template_file.map_roles.*.rendered)
    map_accounts = join("\n", data.template_file.map_accounts.*.rendered)
  }
}

# From Base EKS Module
data "template_file" "launch_template_worker_role_arns" {
  template = file("${path.module}/cluster_configs/auth/worker-role.tpl")

  vars = {
    worker_role_arn = module.eks.worker_iam_role_arn
  }
}

data "template_file" "config_map_aws_auth" {
  template = file(
    "${path.module}/cluster_configs/auth/config-map-aws-auth.yaml.tpl",
  )

  vars = {
    worker_role_arn = join(
      "",
      data.template_file.launch_template_worker_role_arns.*.rendered,
    )
    map_users    = join("\n", data.template_file.map_users.*.rendered)
    map_roles    = join("\n", data.template_file.map_roles.*.rendered)
    map_accounts = join("\n", data.template_file.map_accounts.*.rendered)
  }
}

data "template_file" "map_users" {
  count = length(var.map_users)
  template = file(
    "${path.module}/cluster_configs/auth/config-map-aws-auth-map_users.yaml.tpl",
  )

  vars = {
    user_arn = var.map_users[count.index]["user_arn"]
    username = var.map_users[count.index]["username"]
    group    = var.map_users[count.index]["group"]
  }
}

data "template_file" "map_roles" {
  count = length(var.map_roles)
  template = file(
    "${path.module}/cluster_configs/auth/config-map-aws-auth-map_roles.yaml.tpl",
  )

  vars = {
    role_arn = var.map_roles[count.index]["role_arn"]
    username = var.map_roles[count.index]["username"]
    group    = var.map_roles[count.index]["group"]
  }
}

data "template_file" "map_accounts" {
  count = length(var.map_accounts)
  template = file(
    "${path.module}/cluster_configs/auth/config-map-aws-auth-map_accounts.yaml.tpl",
  )

  vars = {
    account_number = element(var.map_accounts, count.index)
  }
}
