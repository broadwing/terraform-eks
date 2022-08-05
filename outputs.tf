output "dashboard_token" {
  value = var.get_dashboard_token && var.dashboard ? data.kubernetes_secret.dashboard_token[0].data.token : null
}

output "flux_deploy_key" {
  value =  var.flux ? tls_private_key.flux_deploy_key[0].public_key_openssh  : null
}

output "eks" {
  value = module.eks
}
