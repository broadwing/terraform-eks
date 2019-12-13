output "dashboard-token" {
  value = lookup(data.external.dashboard-token[0].result, "token", "")
}

