terraform {
  required_version = ">= 1.0.0"
}

# Cloud Build trigger for CI/CD
resource "google_cloudbuild_trigger" "ci_trigger" {
  name     = "ci-cd-trigger"
  filename = "cloudbuild.yaml"

  github {
    owner = "owner"
    name  = "gcp-kubernetes"
    push {
      branch = "^main$"
    }
  }
}

# Artifact Registry repository
resource "google_artifact_registry_repository" "app_repo" {
  location      = var.region
  repository_id = "${var.project_id}-repo"
  description   = "Docker repository for application images"
  format        = "DOCKER"
}

# Load balancer for ingress
module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 6.3"

  name    = "${var.project_id}-lb"
  project = var.project_id

  ssl                             = true
  managed_ssl_certificate_domains = ["example.com"]
  https_redirect                  = true

  backends = {
    default = {
      description                     = "Default backend for GKE"
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = 300
      enable_cdn                      = true
      security_policy                 = null
      custom_request_headers          = null
      custom_response_headers         = null

      health_check = {
        check_interval_sec  = 5
        timeout_sec         = 5
        healthy_threshold   = 2
        unhealthy_threshold = 10
        request_path        = "/healthz"
        port                = 80
        host                = null
        logging             = true
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group = data.terraform_remote_state.compute.outputs.gke_instance_group
        }
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
    }
  }
}

data "terraform_remote_state" "compute" {
  backend = "gcs"
  config = {
    bucket = "tf-state-gcp-kubernetes"
    prefix = "terraform/state/compute"
  }
}
