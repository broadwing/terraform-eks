output "md5" {
  value = md5(data.template_file.manifest.rendered)
}

