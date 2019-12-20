variable "apply" {
  description = "Set to false to skip"
  default     = "true"
}

variable "kubeconfig" {
  description = "The location of the kubeconfig to use"
}

variable "kubectl_bin" {
  description = "Binary location of kubectl"
  default     = "kubectl"
}

variable "template" {
  description = "Template to use for manifest"
}

variable "vars" {
  type    = map(string)
  default = {}
}

variable "extra_command" {
  description = "If set this will be run before the kubectl apply"
  default     = ""
}
