# allow workers to manage ALBs and Route53 records
resource "aws_iam_role_policy" "eks_workers_albs" {
  name = "alb_manager"
  role = module.eks.worker_iam_role_name

  policy = file("${path.module}/iam/albs.json")
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

