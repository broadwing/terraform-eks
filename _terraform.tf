terraform {
  required_version = ">= 0.14"

  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0.2"
    }

    # Using community kubectl provider for applying raw yaml manifests until kubernetes-terraform-alpha supports it
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.10.0"
    }
  }
}
