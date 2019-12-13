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

