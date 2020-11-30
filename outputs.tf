output "dashboard_token" {
  value = var.get_dashboard_token ? data.kubernetes_secret.dashboard_token.data.token : null
}

output "flux_deploy_key" {
  value = var.flux ? tls_private_key.flux_deploy_key[0].public_key_openssh : null
}

output "eks" {
  value = module.eks
}

output "oidc_provider" {
  value = aws_iam_openid_connect_provider.oidc_provider
}
