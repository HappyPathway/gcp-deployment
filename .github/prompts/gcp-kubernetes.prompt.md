# Deployment Module for GCP Infrastructure

## Overview
This module manages the deployment of core infrastructure services to GKE using Terraform with ArgoCD and Helm providers. It provides a GitOps-based approach to managing Kubernetes resources while maintaining the benefits of Terraform state management.

## Module Structure
```
deployment/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── providers.tf
└── helm/
    ├── argocd/
    │   ├── values.yaml
    │   └── applications/
    │       ├── monitoring.yaml
    │       ├── logging.yaml
    │       └── security.yaml
    └── core-services/
        ├── cert-manager/
        ├── external-dns/
        └── ingress-nginx/
```

## Key Components

### ArgoCD Setup
- ArgoCD installation and configuration via Helm
- Application-of-Applications pattern
- RBAC and SSO integration
- Private repository authentication
- Automated sync policies

### Core Infrastructure Services
- Certificate management (cert-manager)
- DNS management (external-dns)
- Ingress controller (nginx)
- Monitoring stack (Prometheus/Grafana)
- Logging solution (Loki/Promtail)

### GitOps Workflow
- Git repository structure
- Application definitions
- Sync policies
- Health checks
- Rollback procedures

## Required Variables
```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "argocd_config" {
  description = "ArgoCD configuration settings"
  type = object({
    version           = string
    repo_url          = string
    target_revision   = string
    namespace         = string
    create_namespace  = bool
  })
  default = {
    version           = "latest"
    repo_url          = ""
    target_revision   = "HEAD"
    namespace         = "argocd"
    create_namespace  = true
  }
}

variable "helm_releases" {
  description = "List of Helm releases to deploy"
  type = list(object({
    name       = string
    repository = string
    chart      = string
    version    = string
    namespace  = string
    values     = map(any)
  }))
}
```

## Usage Example
```hcl
module "deployment" {
  source = "./modules/deployment"
  
  project_id   = "my-gcp-project"
  region       = "us-central1"
  cluster_name = "my-gke-cluster"
  
  argocd_config = {
    version          = "2.8.0"
    repo_url         = "git@github.com:myorg/k8s-manifests.git"
    target_revision  = "main"
    namespace        = "argocd"
    create_namespace = true
  }
  
  helm_releases = [
    {
      name       = "cert-manager"
      repository = "https://charts.jetstack.io"
      chart      = "cert-manager"
      version    = "v1.12.0"
      namespace  = "cert-manager"
      values     = {
        installCRDs = true
      }
    },
    {
      name       = "ingress-nginx"
      repository = "https://kubernetes.github.io/ingress-nginx"
      chart      = "ingress-nginx"
      version    = "4.7.0"
      namespace  = "ingress-nginx"
      values     = {
        controller = {
          service = {
            type = "LoadBalancer"
          }
        }
      }
    }
  ]
}
```

## Provider Configuration
```hcl
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.22.0"
    }
    argocd = {
      source  = "oboukili/argocd"
      version = "~> 5.0"
    }
  }
}
```

## Outputs
```hcl
output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = module.argocd.admin_password
  sensitive   = true
}

output "argocd_url" {
  description = "ArgoCD server URL"
  value       = module.argocd.server_url
}

output "installed_helm_releases" {
  description = "List of installed Helm releases"
  value       = module.helm_releases[*].metadata
}
```

## Best Practices

### 1. GitOps Implementation
- Use Application-of-Applications pattern
- Implement proper RBAC
- Enable automated sync policies
- Configure health checks
- Set up notifications

### 2. Helm Chart Management
- Version pin all charts
- Use values files for configuration
- Implement proper upgrade strategies
- Configure resource limits
- Enable monitoring and alerts

### 3. Security Considerations
- Use HTTPS endpoints
- Implement network policies
- Configure RBAC properly
- Enable audit logging
- Secure sensitive values

## Regular Maintenance Tasks
- Chart version updates
- Security patch application
- Configuration sync verification
- Health check validation
- Backup verification
- Resource optimization