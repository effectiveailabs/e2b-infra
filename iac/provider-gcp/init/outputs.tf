output "service_account_email" {
  value = google_service_account.infra_instances_service_account.email
}

output "consul_acl_token_secret" {
  value     = google_secret_manager_secret_version.consul_acl_token.secret_data
  sensitive = true
}

output "consul_acl_token_secret_name" {
  value = google_secret_manager_secret.consul_acl_token.secret_id
}

output "nomad_acl_token_secret" {
  value     = google_secret_manager_secret_version.nomad_acl_token.secret_data
  sensitive = true
}

output "nomad_acl_token_secret_name" {
  value = google_secret_manager_secret.nomad_acl_token.secret_id
}

output "core_repository_name" {
  value = data.google_artifact_registry_repository.core.name
}

output "postgres_connection_string_secret_name" {
  value = google_secret_manager_secret.postgres_connection_string.name
}

output "envs_docker_context_bucket_name" {
  value = google_storage_bucket.envs_docker_context.name
}

output "cluster_setup_bucket_name" {
  value = google_storage_bucket.setup_bucket.name
}

output "fc_env_pipeline_bucket_name" {
  value = google_storage_bucket.fc_env_pipeline_bucket.name
}

output "fc_kernels_bucket_name" {
  value = google_storage_bucket.fc_kernels_bucket.name
}

output "fc_versions_bucket_name" {
  value = google_storage_bucket.fc_versions_bucket.name
}

output "fc_template_bucket_name" {
  value = google_storage_bucket.fc_template_bucket.name
}

output "fc_build_cache_bucket_name" {
  value = google_storage_bucket.fc_build_cache_bucket.name
}
