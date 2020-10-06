data "kubectl_path_documents" "efs_resources" {
  pattern = "${path.module}/cluster_configs/efs-storage-class.tpl.yaml"
  vars = {
  }
}

resource "kubectl_manifest" "efs_resources" {
  count     = var.enable_efs_csi ? length(data.kubectl_path_documents.efs_resources.documents) : 0
  force_new = true

  yaml_body = element(data.kubectl_path_documents.efs_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}

data "kubectl_path_documents" "efs_csi_driver_resources" {
  pattern = "${path.module}/cluster_configs/aws-efs-csi-driver.tpl.yaml"
  vars = {
  }
}

resource "kubectl_manifest" "efs_csi_driver_resources" {
  count     = var.enable_efs_csi ? length(data.kubectl_path_documents.efs_csi_driver_resources.documents) : 0
  force_new = true

  yaml_body = element(data.kubectl_path_documents.efs_csi_driver_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}
