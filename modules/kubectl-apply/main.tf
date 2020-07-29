locals {
  bin_path    = abspath("${path.module}/bin")
  path_export = var.use_system_kubectl ? "" : "PATH=${local.bin_path}:$PATH"
}

data "template_file" "manifest" {
  count    = var.apply == "true" && var.template != null ? 1 : 0
  template = var.template

  vars = var.vars
}

resource "null_resource" "command" {
  count = var.apply == "true" && var.extra_command != null ? 1 : 0

  triggers = {
    extra_command = md5(var.extra_command)
    template      = var.template != null ? md5(data.template_file.manifest[0].rendered) : ""
  }

  provisioner "local-exec" {
    command = <<-EOT
    ${local.path_export}
    ${var.extra_command}
    EOT

    environment = {
      KUBECONFIG = var.kubeconfig
    }
  }

  depends_on = [var.module_depends_on]
}

resource "null_resource" "apply" {
  count = var.apply == "true" && var.template != null ? 1 : 0

  triggers = {
    template = md5(data.template_file.manifest[0].rendered)
  }

  provisioner "local-exec" {
    command = <<EOT
${local.path_export}
cat <<'EOF' | kubectl apply -f -
${data.template_file.manifest[0].rendered}
EOF
EOT

    environment = {
      KUBECONFIG = var.kubeconfig
    }
  }

  depends_on = [var.module_depends_on]
}
