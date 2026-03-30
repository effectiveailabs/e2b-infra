output "project_id" {
  value = var.project_id
}

output "network_name" {
  value = data.google_compute_network.main.name
}

output "subnetwork_name" {
  value = data.google_compute_subnetwork.main.name
}

output "service_account_email" {
  value = module.init.service_account_email
}

output "terraform_state_bucket" {
  value = google_storage_bucket.terraform_state.name
}

output "storage_buckets" {
  value = {
    templates       = module.init.fc_template_bucket_name
    docker_contexts = module.init.envs_docker_context_bucket_name
    env_pipeline    = module.init.fc_env_pipeline_bucket_name
    instance_setup  = module.init.cluster_setup_bucket_name
    build_cache     = module.init.fc_build_cache_bucket_name
  }
}

output "artifact_registry_repositories" {
  value = {
    core         = "${var.region}-docker.pkg.dev/${var.project_id}/${var.core_repository_id}"
    environments = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.custom_environments_repository.repository_id}"
  }
}

output "cloud_sql" {
  value = {
    instance_name   = google_sql_database_instance.e2b.name
    connection_name = google_sql_database_instance.e2b.connection_name
    private_ip      = google_sql_database_instance.e2b.private_ip_address
    database        = google_sql_database.e2b.name
    user            = google_sql_user.e2b.name
  }
}

output "secret_names" {
  value = {
    db_password      = google_secret_manager_secret.db_password.secret_id
    db_connection    = module.init.postgres_connection_string_secret_name
    api_admin_token  = google_secret_manager_secret.api_admin_token.secret_id
    nomad_acl_token  = module.init.nomad_acl_token_secret_name
    consul_acl_token = module.init.consul_acl_token_secret_name
  }
}

output "sandbox_dns_zone" {
  value = module.cluster.sandbox_dns_zone
}

output "internal_lb_ip" {
  value = module.cluster.internal_lb_ip
}

output "sandbox_domain" {
  value = module.cluster.sandbox_domain
}

output "nomad_address" {
  value = "http://nomad.${module.cluster.sandbox_domain}"
}

