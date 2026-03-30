resource "google_service_account" "docker_registry_service_account" {
  account_id   = "e2b-${var.environment}-docker-proxy-sa"
  display_name = "Docker Reverse Proxy Service Account"
}

# Use project-level IAM instead of repo-level IAM to avoid needing
# artifactregistry.repositories.setIamPolicy permission.
resource "google_project_iam_member" "docker_proxy_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.docker_registry_service_account.email}"
}

# SA key removed — blocked by org policy (iam.disableServiceAccountKeyCreation).
# The docker-reverse-proxy Nomad job uses WIF via the node's attached SA, not a key.
