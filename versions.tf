
terraform {
  required_version = ">= 1"

  # Using community kubectl provider for applying raw yaml manifests until kubernetes-terraform-alpha supports it
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.11.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.3.2"
    }
  }
}
