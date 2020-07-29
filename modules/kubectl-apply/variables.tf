variable "apply" {
  description = "Set to false to skip"
  default     = "true"
}

variable "kubeconfig" {
  description = "The location of the kubeconfig to use"
}

variable "template" {
  description = "Template to use for manifest"
  default     = null
}

variable "vars" {
  type    = map(string)
  default = {}
}

variable "extra_command" {
  description = "If set this will be run before the kubectl apply"
  default     = null
}

variable "module_depends_on" {
  description = "List of module depends on resources"
  type        = list
  default     = []
}

variable "use_system_kubectl" {
  description = "If system kubectl and iam-authenticator should be used. Embedded version is for linux"
  type        = bool
  default     = false
}
