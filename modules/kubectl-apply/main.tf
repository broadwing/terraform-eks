locals {
  bin_path = abspath("${path.module}/bin")
}

data "template_file" "manifest" {
  count = var.apply == "true" && var.template != null ? 1 : 0
  template = var.template

  vars = var.vars
}

resource "null_resource" "command" {
  count = var.appy == "true" && var.extra_command != null ? 1 : 0

  triggers = {
    extra_command = md5(var.extra_command)
  }

  provisioner "local-exec" {
    command = <<-EOT
    PATH=${local.bin_path}:$PATH
    ${var.extra_command}
    EOT

    environment = {
      KUBECONFIG = var.kubeconfig
    }
  }
}

resource "null_resource" "apply" {
  count = var.apply == "true" && var.template != null ? 1 : 0

  triggers = {
    template      = md5(data.template_file.manifest.rendered)
  }

  provisioner "local-exec" {
    command = <<EOT
PATH=${local.bin_path}:$PATH
cat <<'EOF' | kubectl apply -f -
${data.template_file.manifest.rendered}
EOF
EOT

    environment = {
      KUBECONFIG = var.kubeconfig
    }
  }

  depends_on = [null_resource.command]
}
