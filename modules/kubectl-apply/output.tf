output "md5" {
  value = var.apply == "true" && var.template != null ? md5(data.template_file.manifest[0].rendered) : ""
}

output "command_id" {
  value = var.apply == "true" && var.extra_command != null ? null_resource.command[0].id : ""
}
