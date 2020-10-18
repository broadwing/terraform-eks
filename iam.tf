# allow workers to manage ALBs and Route53 records
# Policy is from: https://github.com/kubernetes-sigs/aws-alb-ingress-controller/blob/v2_ga/docs/install/iam_policy.json
resource "aws_iam_role_policy" "eks_workers_albs" {
  name = "alb_manager"
  role = module.eks.worker_iam_role_name

  policy = var.alb_ingress_controller_v2 ? file("${path.module}/iam/albs_v2.json") : file("${path.module}/iam/albs.json")
}

resource "aws_iam_role_policy" "eks_workers_route53" {
  name = "route53_manager"
  role = module.eks.worker_iam_role_name

  policy = file("${path.module}/iam/route53.json")
}

resource "aws_iam_role_policy_attachment" "AmazonEC2RoleForSSM" {
  role       = module.eks.worker_iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# Enable permissions for autoscaling
resource "aws_iam_role_policy_attachment" "workers_autoscaling" {
  policy_arn = aws_iam_policy.worker_autoscaling.arn
  role       = module.eks.worker_iam_role_name
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "eks-worker-autoscaling-${module.eks.cluster_id}"
  description = "EKS worker node autoscaling policy for cluster ${module.eks.cluster_id}"
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
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

# CSI drivers
resource "aws_iam_role_policy_attachment" "aws_csi_ebs" {
  count      = var.enable_ebs_csi ? 1 : 0
  policy_arn = aws_iam_policy.amazon_ebs_csi_driver.arn
  role       = module.eks.worker_iam_role_name
}
