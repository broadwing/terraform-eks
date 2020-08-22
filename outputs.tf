output "dashboard_token" {
  value = var.get_dashboard_token ? data.kubernetes_secret.dashboard_token.data.token : null
}

output "eks" {
  value = module.eks
}
