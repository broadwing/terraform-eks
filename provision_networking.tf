
# TODO need to simulate
# extra_command = var.remove_aws_vpc_cni ? "kubectl --namespace kube-system delete daemonsets aws-node" : ""
data "kubectl_path_documents" "genie_resources" {
  pattern = "${path.module}/cluster_configs/genie.tpl.yaml"
  vars = {
    default_plugins = var.calico_cni ? "calico" : ""
  }
}

data "kubectl_path_documents" "calico_resources" {
  pattern = "${path.module}/cluster_configs/calico.tpl.yaml"
  vars = {
    ip_autodetection = var.remove_aws_vpc_cni ? "first-found" : "interface=eth0"
  }
}

data "kubectl_path_documents" "aws_k8s_cni_resources" {
  pattern = "${path.module}/cluster_configs/aws-k8s-cni.tpl.yaml"
  vars = {
    externalsnat     = var.calico_cni ? "true" : "false"
    excludesnatcidrs = var.calico_cni ? "192.168.0.0/16" : "false"
    disabled         = var.remove_aws_vpc_cni
  }
}

data "kubectl_path_documents" "k8s_dns_resources" {
  pattern = "${path.module}/cluster_configs/dns.tpl.yaml"
  vars = {
    cni = var.remove_aws_vpc_cni ? "" : "aws"
  }
}

resource "kubectl_manifest" "genie_resources" {
  count = var.genie_cni ? length(data.kubectl_path_documents.genie_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.genie_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  # Forces waiting for cluster to be available
  depends_on = [module.eks.cluster_id]
}

resource "kubectl_manifest" "calico_resources" {
  count = var.calico_cni ? length(data.kubectl_path_documents.calico_resources.documents) : 0

  yaml_body = element(data.kubectl_path_documents.calico_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  depends_on = [
    # Forces waiting for cluster to be available
    module.eks.cluster_id,
    kubectl_manifest.genie_resources
  ]
}

resource "kubectl_manifest" "aws_k8s_cni_resources" {
  count     = length(data.kubectl_path_documents.aws_k8s_cni_resources.documents)
  force_new = true

  yaml_body = element(data.kubectl_path_documents.aws_k8s_cni_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  depends_on = [
    # Forces waiting for cluster to be available
    module.eks.cluster_id,
    kubectl_manifest.calico_resources
  ]
}

resource "kubectl_manifest" "k8s_dns_resources" {
  count     = var.genie_cni ? length(data.kubectl_path_documents.k8s_dns_resources.documents) : 0
  force_new = true

  yaml_body = element(data.kubectl_path_documents.k8s_dns_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  depends_on = [
    # Forces waiting for cluster to be available
    module.eks.cluster_id,
    kubectl_manifest.genie_resources
  ]
}
