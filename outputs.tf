output "dashboard-token" {
  value = var.get_dashboard_token == "true" ? lookup(data.external.dashboard-token[0].result, "token", ""): ""
}

output "eks" {
  value = module.eks
}
