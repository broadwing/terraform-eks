# Allow ssh from internal instances
resource "aws_security_group_rule" "allow_all" {
  count = var.allow_ssh ? 1 : 0

  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [var.allow_ssh_cidr]

  security_group_id = module.eks.worker_security_group_id
}

# Allow managed and non managed nodes to talk to eachother
resource "aws_security_group_rule" "non_manged_to_managed" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  security_group_id        = module.eks.cluster_primary_security_group_id
  source_security_group_id = module.eks.worker_security_group_id
}

resource "aws_security_group_rule" "manged_to_non_managed" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  security_group_id        = module.eks.worker_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}
