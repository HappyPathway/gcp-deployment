variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resource deployment"
  type        = string
}

output "lb_external_ip" {
  value = module.lb-http.external_ip
}

output "artifact_registry_repository_id" {
  value = google_artifact_registry_repository.app_repo.id
}

output "cloudbuild_trigger_id" {
  value = google_cloudbuild_trigger.ci_trigger.id
}
