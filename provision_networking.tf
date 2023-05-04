resource "kubectl_manifest" "aws_node_patch" {
  count            = var.use_vpc_cni_prefix_delegation ? 1 : 0
  wait_for_rollout = false

  # Do only a patch
  server_side_apply = true
  apply_only        = true

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
              - name: ENABLE_PREFIX_DELEGATION
                value: "true"
              - name: WARM_IP_TARGET
                value: "5"
              - name: MINIMUM_IP_TARGET
                value: "2"
    EOT

  # Forces waiting for cluster to be available
  depends_on = [var.eks_module_cluster_arn]
}
