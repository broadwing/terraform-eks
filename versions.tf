
terraform {
  required_version = ">= 1"

  # Using community kubectl provider for applying raw yaml manifests until kubernetes-terraform-alpha supports it
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.45"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
    }
  }
}
