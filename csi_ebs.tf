data "aws_iam_policy_document" "ebs_csi_driver" {
  version = "2012-10-17"

  statement {
    sid    = "AmazonEBSCSIDriver"
    effect = "Allow"

    actions = [
      "ec2:AttachVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "amazon_ebs_csi_driver" {
  name   = "${var.environment}_Amazon_EBS_CSI_Driver"
  path   = "/"
  policy = data.aws_iam_policy_document.ebs_csi_driver.json
}
