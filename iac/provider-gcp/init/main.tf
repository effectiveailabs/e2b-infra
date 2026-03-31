resource "google_project_service" "secrets_manager_api" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry_api" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "time_sleep" "secrets_api_wait_60_seconds" {
  depends_on      = [google_project_service.secrets_manager_api]
  create_duration = "60s"
}

resource "time_sleep" "artifact_registry_api_wait_90_seconds" {
  depends_on      = [google_project_service.artifact_registry_api]
  create_duration = "90s"
}

resource "google_service_account" "infra_instances_service_account" {
  account_id   = trimsuffix(substr(replace("${var.prefix}infra", "_", "-"), 0, 30), "-")
  display_name = "E2B infra instances (${var.environment})"
}

data "google_artifact_registry_repository" "core" {
  location      = var.gcp_region
  repository_id = var.core_repository_id
  depends_on    = [time_sleep.artifact_registry_api_wait_90_seconds]
}

resource "google_project_iam_member" "infra_sa_ar_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.infra_instances_service_account.email}"
}

resource "google_project_iam_member" "infra_sa_compute_viewer" {
  project = var.gcp_project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.infra_instances_service_account.email}"
}
