terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

# context / clustername / kubeconfig set in Makefile
provider "kubernetes" {
  config_path    = "kubeconfig"
  config_context = "kind-kind-local"
}

provider "helm" {
  kubernetes {
    config_path            = "kubeconfig"
    config_context_cluster = "kind-kind-local"
  }
}
