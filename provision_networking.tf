data "kubectl_path_documents" "genie_resources" {
  count     = var.calico_cni ? 1 : 0

  pattern = "${path.module}/cluster_configs/genie.tpl.yaml"
  vars = {
    default_plugins = var.calico_cni ? "calico" : ""
  }
}

data "kubectl_path_documents" "calico_resources" {
  count     = var.calico_cni ? 1 : 0

  pattern = "${path.module}/cluster_configs/calico.tpl.yaml"
  vars = {
    ip_autodetection = "interface=eth0"
  }
}

resource "kubectl_manifest" "genie_resources" {
  count = var.calico_cni ? length(data.kubectl_path_documents.genie_resources[0].documents) : 0

  yaml_body = element(data.kubectl_path_documents.genie_resources[0].documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}

resource "kubectl_manifest" "calico_resources" {
  count = var.calico_cni ? length(data.kubectl_path_documents.calico_resources[0].documents) : 0

  yaml_body = element(data.kubectl_path_documents.calico_resources[0].documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  depends_on = [
    # Forces waiting for cluster to be available
    module.eks.cluster_id,
    kubectl_manifest.genie_resources
  ]
}

resource "kubectl_manifest" "aws_node_patch" {
  count     = var.calico_cni ? 1 : 0
  wait_for_rollout = false

  # Do only a patch
  server_side_apply = true
  apply_only = true

  yaml_body = <<-EOT
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      name: aws-node
      namespace: kube-system
    spec:
      template:
        spec:
          containers:
            - name: aws-node
              env:
              - name: AWS_VPC_K8S_CNI_EXTERNALSNAT
                value: "true"
              - name: AWS_VPC_K8S_CNI_EXCLUDE_SNAT_CIDRS
                value: "192.168.0.0/16"
    EOT

  depends_on = [
    # Forces waiting for cluster to be available
    module.eks.cluster_id,
    # kubectl_manifest.calico_resources,
  ]

}

resource "kubectl_manifest" "core_dns_patch" {
  count     = var.calico_cni ? 1 : 0
  wait_for_rollout = false

  # Do only a patch
  server_side_apply = true
  apply_only = true

  yaml_body = <<-EOT
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: coredns
      namespace: kube-system
    spec:
      template:
        metadata:
          annotations:
            cni: aws
    EOT

  depends_on = [
    # Forces waiting for cluster to be available
    module.eks.cluster_id,
    # kubectl_manifest.calico_resources
  ]

}
