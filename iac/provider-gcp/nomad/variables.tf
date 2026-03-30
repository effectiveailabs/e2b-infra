variable "envd_timeout" { type = string }
variable "prefix" { type = string }
variable "gcp_zone" { type = string }
variable "orchestrator_node_pool" { type = string }
variable "core_repository_name" { type = string }
variable "consul_acl_token_secret" { type = string }
variable "template_bucket_name" { type = string }
variable "build_cache_bucket_name" { type = string }
variable "builder_node_pool" { type = string }
variable "nomad_acl_token_secret" { type = string }
variable "nomad_port" { type = number }

variable "api_port" {
  type = object({
    name        = string
    port        = number
    health_path = string
  })
}

variable "api_grpc_port" {
  type    = number
  default = 5009
}

variable "ingress_port" {
  type = object({
    name        = string
    port        = number
    health_path = string
  })
}

variable "additional_traefik_arguments" {
  type = list(string)
}

variable "ingress_count" { type = number }
variable "api_resources_cpu_count" { type = number }
variable "api_resources_memory_mb" { type = number }
variable "api_secret" { type = string }
variable "api_admin_token" { type = string }
variable "sandbox_access_token_hash_seed" { type = string }

variable "sandbox_storage_backend" {
  type    = string
  default = "memory"
}

variable "db_max_open_connections" { type = number }
variable "db_min_idle_connections" { type = number }
variable "auth_db_max_open_connections" { type = number }
variable "auth_db_min_idle_connections" { type = number }
variable "environment" { type = string }
variable "api_server_count" { type = number }
variable "api_machine_count" { type = number }
variable "api_node_pool" { type = string }
variable "custom_envs_repository_name" { type = string }
variable "gcp_project_id" { type = string }
variable "gcp_region" { type = string }
variable "postgres_connection_string_secret_name" { type = string }
variable "postgres_connection_string_secret_version_dependency" { type = any }
variable "postgres_read_replica_connection_string_secret_version" { type = any }
variable "client_proxy_count" { type = number }
variable "client_proxy_resources_memory_mb" { type = number }
variable "client_proxy_resources_cpu_count" { type = number }
variable "client_proxy_update_max_parallel" { type = number }
variable "client_proxy_session_port" { type = number }
variable "client_proxy_health_port" { type = number }
variable "domain_name" { type = string }

variable "docker_reverse_proxy_port" {
  type = object({
    name        = string
    port        = number
    health_path = string
  })
}

variable "orchestrator_port" { type = number }
variable "orchestrator_proxy_port" { type = number }
variable "fc_env_pipeline_bucket_name" { type = string }
variable "allow_sandbox_internet" { type = bool }
variable "template_manager_port" { type = number }
variable "template_manages_clusters_size_gt_1" { type = bool }

variable "nomad_autoscaler_version" {
  type        = string
  description = "Version of the Nomad Autoscaler to deploy"
  default     = "0.4.5"
}

variable "redis_port" {
  type = object({
    name = string
    port = number
  })
}

variable "gcs_grpc_connection_pool_size" {
  description = "Number of gRPC connections in the GCS connection pool"
  type        = number
}

variable "orchestrator_env_vars" {
  type    = map(string)
  default = {}
}
