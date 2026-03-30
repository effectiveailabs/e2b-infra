data "google_compute_global_address" "private_ip_range" {
  name    = "private-ip-address"
  project = var.project_id
}

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!@#%^*-_+="
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "e2b-${var.environment}-db-password"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_sql_database_instance" "e2b" {
  name                = coalesce(var.db_instance_name, "e2b-${var.environment}-postgres")
  database_version    = "POSTGRES_16"
  region              = var.region
  deletion_protection = var.db_deletion_protection

  settings {
    tier              = var.db_tier
    availability_type = var.db_availability_type
    disk_type         = "PD_SSD"
    disk_size         = var.db_disk_size_gb
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = data.google_compute_network.main.id
      enable_private_path_for_google_cloud_services = true
    }

    maintenance_window {
      day  = 7
      hour = 3
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 2048
      record_application_tags = true
      record_client_address   = true
    }

    user_labels = local.common_labels
  }

  depends_on = [
    google_project_service.enabled,
    data.google_compute_global_address.private_ip_range,
  ]
}

resource "google_sql_database" "e2b" {
  name     = var.db_name
  instance = google_sql_database_instance.e2b.name
}

resource "google_sql_user" "e2b" {
  name     = var.db_user
  instance = google_sql_database_instance.e2b.name
  password = random_password.db_password.result
}

resource "google_secret_manager_secret_version" "postgres_connection_string" {
  secret = module.init.postgres_connection_string_secret_name
  secret_data = format(
    "postgres://%s:%s@%s:5432/%s?sslmode=disable",
    google_sql_user.e2b.name,
    urlencode(random_password.db_password.result),
    google_sql_database_instance.e2b.private_ip_address,
    google_sql_database.e2b.name,
  )
}
