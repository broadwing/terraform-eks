# If this hangs and you have partial installs, delete existing CRDs
data "kubectl_path_documents" "cert_manager_crd_resources" {
  pattern = "${path.module}/cert-manager/crd/*.yaml"
  vars = {
  }
}

resource "kubectl_manifest" "cert_manager_crd_resources" {
  count = var.install_cert_manager ? length(data.kubectl_path_documents.cert_manager_crd_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.cert_manager_crd_resources.documents, count.index)

  validate_schema = false

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}

data "kubectl_path_documents" "cert_manager_resources" {
  pattern = "${path.module}/cert-manager/*.yaml"
  vars = {
    namespace     = var.cert_manager_namespace
    release_name  = var.cert_manager_release_name
    cni           = var.cert_manager_cni
    image_version = var.cert_manager_image_version
  }
}

resource "kubectl_manifest" "cert_manager_resources" {
  count = var.install_cert_manager ? length(data.kubectl_path_documents.cert_manager_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.cert_manager_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id, kubectl_manifest.cert_manager_crd_resources]
}
