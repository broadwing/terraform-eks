################################################################################
# Policies
################################################################################

# allow workers to manage ALBs and Route53 records
resource "aws_iam_policy" "eks_workers_albs" {
  name_prefix = "alb-manager-${var.cluster_name}"
  description = "Allow cluster to manager albs for alb ingress controller"
  policy      = file("${path.module}/iam/albs.json")
}

resource "aws_iam_policy" "eks_workers_route53" {
  name_prefix = "route53-manager-${var.cluster_name}"
  description = "Allow cluster to manager route53 records for external dns"
  policy      = file("${path.module}/iam/route53.json")
}

# Permissions for autoscaling
resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "eks-worker-autoscaling-${var.cluster_name}"
  description = "EKS worker node autoscaling policy for cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
}

data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}
