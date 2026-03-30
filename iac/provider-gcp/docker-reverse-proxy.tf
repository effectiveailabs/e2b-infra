# Docker reverse proxy SA — kept for future use.
# AR writer grant requires Owner/IAM Admin permissions (skipped for now).
# The reverse proxy job inherits the VM SA for reads; writes need manual IAM grant.

resource "google_service_account" "docker_registry_service_account" {
  account_id   = "e2b-${var.environment}-docker-proxy-sa"
  display_name = "Docker Reverse Proxy Service Account"
}
