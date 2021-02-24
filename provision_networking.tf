
# TODO need to simulate
# extra_command = var.remove_aws_vpc_cni ? "kubectl --namespace kube-system delete daemonsets aws-node" : ""
data "kubectl_path_documents" "genie_resources" {
  pattern = "${path.module}/cluster_configs/genie.tpl.yaml"
  vars = {
    default_plugins = var.calico_cni ? "calico" : ""
  }
}

data "kubectl_path_documents" "calico_resources" {
  pattern = "${path.module}/cluster_configs/calico-onprem-3.16.5.tpl.yaml"
  vars = {
    ip_autodetection = var.remove_aws_vpc_cni ? "first-found" : "interface=eth0"
  }
}

data "kubectl_path_documents" "aws_cni_resources" {
  pattern = "${path.module}/cluster_configs/amazon-k8-cni-1.7.9.tpl.yaml"
  vars = {
    externalsnat     = var.calico_cni ? "true" : "false"
    excludesnatcidrs = var.calico_cni ? "192.168.0.0/16" : "false"
    disabled         = var.remove_aws_vpc_cni
  }
}

data "kubernetes_service" "kube_dns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
  }

  depends_on = [module.eks.cluster_id]
}

# A dummy group of documents so count can be evaluated
# even though template values are not yet known
data "kubectl_path_documents" "k8s_dns_resources_count" {
  count = var.enable_coredns ? 1 : 0
  pattern = "${path.module}/cluster_configs/dns.tpl.yaml"
  disable_template = true
}

data "kubectl_path_documents" "k8s_dns_resources" {
  count = var.enable_coredns ? 1 : 0
  pattern = "${path.module}/cluster_configs/dns.tpl.yaml"

  vars = {
    cni            = var.remove_aws_vpc_cni ? "" : "aws"
    region         = var.default_region
    dns_cluster_ip = data.kubernetes_service.kube_dns.spec.0.cluster_ip
  }

  depends_on = [
    module.eks.cluster_id,
    data.kubernetes_service.kube_dns,
  ]
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

resource "kubectl_manifest" "aws_cni_resources" {
  count     = length(data.kubectl_path_documents.aws_cni_resources.documents)
  force_new = true

  yaml_body = element(data.kubectl_path_documents.aws_cni_resources.documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  depends_on = [
    # Forces waiting for cluster to be available
    module.eks.cluster_id,
    kubectl_manifest.calico_resources
  ]
}

resource "kubectl_manifest" "k8s_dns_resources" {
  count = var.enable_coredns ? var.genie_cni ? length(data.kubectl_path_documents.k8s_dns_resources_count[0].documents[0]) : 0 : 0

  force_new = true

  yaml_body = element(data.kubectl_path_documents.k8s_dns_resources[0].documents, count.index)

  # We wont have any nodes yet so can't wait for rollout
  wait_for_rollout = false

  depends_on = [
    # Forces waiting for cluster to be available
    module.eks.cluster_id,
    data.kubectl_path_documents.k8s_dns_resources,
  ]
}
