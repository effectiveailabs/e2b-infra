resource "google_service_account" "docker_registry_service_account" {
  account_id   = "e2b-${var.environment}-docker-proxy-sa"
  display_name = "Docker Reverse Proxy Service Account"
}

resource "google_project_iam_member" "docker_proxy_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.docker_registry_service_account.email}"
}
