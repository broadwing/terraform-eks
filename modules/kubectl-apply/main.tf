data "template_file" "manifest" {
  template = var.template

  vars = var.vars
}

resource "null_resource" "apply" {
  count = var.apply == "true" ? 1 : 0

  triggers = {
    template      = md5(data.template_file.manifest.rendered)
    extra_command = md5(var.extra_command)
  }

  provisioner "local-exec" {
    command = <<EOT
${var.extra_command}

cat <<'EOF' | ${var.kubectl_bin} apply -f -
${data.template_file.manifest.rendered}
EOF
EOT


    environment = {
      KUBECONFIG = var.kubeconfig
    }
  }
}

