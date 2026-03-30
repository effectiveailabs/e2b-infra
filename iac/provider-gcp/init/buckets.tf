resource "google_storage_bucket" "envs_docker_context" {
  name                        = var.docker_context_bucket_name
  location                    = var.gcp_region
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels                      = var.labels
}

resource "google_storage_bucket" "setup_bucket" {
  name                        = var.setup_bucket_name
  location                    = var.gcp_region
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels                      = var.labels
}

resource "google_storage_bucket" "fc_kernels_bucket" {
  name                        = var.fc_kernels_bucket_name
  location                    = var.gcp_region
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels                      = var.labels
}

resource "google_storage_bucket" "fc_versions_bucket" {
  name                        = var.fc_versions_bucket_name
  location                    = var.gcp_region
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels                      = var.labels
}

resource "google_storage_bucket" "fc_env_pipeline_bucket" {
  name                        = var.fc_env_pipeline_bucket_name
  location                    = var.template_bucket_location
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels                      = var.labels
}

resource "google_storage_bucket" "fc_template_bucket" {
  name                        = var.template_bucket_name
  location                    = var.gcp_region
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  autoclass {
    enabled                = true
    terminal_storage_class = "ARCHIVE"
  }
  lifecycle_rule {
    action { type = "AbortIncompleteMultipartUpload" }
    condition { age = 1 }
  }
  lifecycle_rule {
    action { type = "Delete" }
    condition {
      days_since_noncurrent_time = 0
      send_age_if_zero           = false
      with_state                 = "ARCHIVED"
    }
  }
  versioning { enabled = true }
  soft_delete_policy { retention_duration_seconds = 864000 }
  labels = var.labels
}

resource "google_storage_bucket" "fc_build_cache_bucket" {
  name                        = var.build_cache_bucket_name
  location                    = var.gcp_region
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  autoclass { enabled = true }
  soft_delete_policy { retention_duration_seconds = 0 }
  labels = var.labels
}

resource "google_storage_bucket_iam_member" "envs_docker_context_iam" {
  bucket = google_storage_bucket.envs_docker_context.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.vm_service_account_email}"
}

resource "google_storage_bucket_iam_member" "envs_pipeline_iam" {
  bucket = google_storage_bucket.fc_env_pipeline_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.vm_service_account_email}"
}

resource "google_storage_bucket_iam_member" "instance_setup_bucket_iam" {
  bucket = google_storage_bucket.setup_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.vm_service_account_email}"
}

resource "google_storage_bucket_iam_member" "fc_kernels_bucket_iam" {
  bucket = google_storage_bucket.fc_kernels_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.vm_service_account_email}"
}

resource "google_storage_bucket_iam_member" "fc_versions_bucket_iam" {
  bucket = google_storage_bucket.fc_versions_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.vm_service_account_email}"
}

resource "google_storage_bucket_iam_member" "fc_build_cache_bucket_iam" {
  bucket = google_storage_bucket.fc_build_cache_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.vm_service_account_email}"
}

resource "google_storage_bucket_iam_member" "fc_template_bucket_iam" {
  bucket = google_storage_bucket.fc_template_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.vm_service_account_email}"
}

resource "google_storage_bucket_iam_member" "fc_template_bucket_iam_reader" {
  bucket = google_storage_bucket.fc_template_bucket.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${var.vm_service_account_email}"
}
