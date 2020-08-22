
terraform {
  required_version = ">= 0.13"

  # Using community kubectl provider for applying raw yaml manifests until kubernetes-terraform-alpha supports it
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.6.2"
    }
  }
}
