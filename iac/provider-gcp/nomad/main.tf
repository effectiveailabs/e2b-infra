locals {
  redis_url           = "redis.service.consul:${var.redis_port.port}"
  redis_cluster_url   = ""
  redis_tls_ca_base64 = ""
}

# API

data "google_secret_manager_secret_version" "postgres_connection_string" {
  secret = var.postgres_connection_string_secret_name
}

data "google_secret_manager_secret_version" "postgres_read_replica_connection_string" {
  secret = var.postgres_read_replica_connection_string_secret_version.secret
}

provider "nomad" {
  address      = "http://nomad.${var.domain_name}"
  secret_id    = var.nomad_acl_token_secret
  consul_token = var.consul_acl_token_secret
}

module "ingress" {
  source = "../../modules/job-ingress"

  ingress_count                = var.ingress_count
  ingress_proxy_port           = var.ingress_port.port
  additional_traefik_arguments = var.additional_traefik_arguments

  node_pool     = var.api_node_pool
  update_stanza = var.api_machine_count > 1

  nomad_token  = var.nomad_acl_token_secret
  consul_token = var.consul_acl_token_secret
}

module "api" {
  source = "../../modules/job-api"

  update_stanza      = var.api_machine_count > 1
  node_pool          = var.api_node_pool
  prevent_colocation = var.api_machine_count > 2
  count_instances    = var.api_server_count

  memory_mb = var.api_resources_memory_mb
  cpu_count = var.api_resources_cpu_count

  domain_name                             = var.domain_name
  orchestrator_port                       = var.orchestrator_port
  port_name                               = var.api_port.name
  port_number                             = var.api_port.port
  api_grpc_port                           = var.api_grpc_port
  api_docker_image                        = data.google_artifact_registry_docker_image.api_image.self_link
  postgres_connection_string              = data.google_secret_manager_secret_version.postgres_connection_string.secret_data
  postgres_read_replica_connection_string = trimspace(data.google_secret_manager_secret_version.postgres_read_replica_connection_string.secret_data)
  environment                             = var.environment
  nomad_acl_token                         = var.nomad_acl_token_secret
  admin_token                             = var.api_admin_token
  redis_url                               = local.redis_url
  redis_cluster_url                       = local.redis_cluster_url
  redis_tls_ca_base64                     = local.redis_tls_ca_base64
  sandbox_access_token_hash_seed          = var.sandbox_access_token_hash_seed
  sandbox_storage_backend                 = var.sandbox_storage_backend
  db_max_open_connections                 = var.db_max_open_connections
  db_min_idle_connections                 = var.db_min_idle_connections
  auth_db_max_open_connections            = var.auth_db_max_open_connections
  auth_db_min_idle_connections            = var.auth_db_min_idle_connections
  db_migrator_docker_image                = data.google_artifact_registry_docker_image.db_migrator_image.self_link
}

module "redis" {
  source = "../../modules/job-redis"

  node_pool   = var.api_node_pool
  port_number = var.redis_port.port
  port_name   = var.redis_port.name
}

resource "nomad_job" "docker_reverse_proxy" {
  jobspec = templatefile("${path.module}/jobs/docker-reverse-proxy.hcl", {
    gcp_zone                   = var.gcp_zone
    node_pool                  = var.api_node_pool
    image_name                 = data.google_artifact_registry_docker_image.docker_reverse_proxy_image.self_link
    postgres_connection_string = data.google_secret_manager_secret_version.postgres_connection_string.secret_data
    port_number                = var.docker_reverse_proxy_port.port
    port_name                  = var.docker_reverse_proxy_port.name
    health_check_path          = var.docker_reverse_proxy_port.health_path
    domain_name                = var.domain_name
    gcp_project_id             = var.gcp_project_id
    gcp_region                 = var.gcp_region
    docker_registry            = var.custom_envs_repository_name
  })
}

module "client_proxy" {
  source = "../../modules/job-client-proxy"

  update_stanza                    = var.api_machine_count > 1
  client_proxy_count               = var.client_proxy_count
  client_proxy_cpu_count           = var.client_proxy_resources_cpu_count
  client_proxy_memory_mb           = var.client_proxy_resources_memory_mb
  client_proxy_update_max_parallel = var.client_proxy_update_max_parallel

  node_pool   = var.api_node_pool
  environment = var.environment

  proxy_port  = var.client_proxy_session_port
  health_port = var.client_proxy_health_port

  redis_url           = local.redis_url
  redis_cluster_url   = local.redis_cluster_url
  redis_tls_ca_base64 = local.redis_tls_ca_base64
  image               = data.google_artifact_registry_docker_image.client_proxy_image.self_link
  api_grpc_address    = "api-grpc.service.consul:${var.api_grpc_port}"
}

data "google_storage_bucket_object" "orchestrator" {
  name   = "orchestrator"
  bucket = var.fc_env_pipeline_bucket_name
}

data "external" "orchestrator_checksum" {
  program = ["bash", "${path.module}/scripts/checksum.sh"]

  query = {
    base64 = data.google_storage_bucket_object.orchestrator.md5hash
  }
}

locals {
  orchestrator_artifact_source = var.environment == "dev" ? "gcs::https://www.googleapis.com/storage/v1/${var.fc_env_pipeline_bucket_name}/orchestrator?version=${data.external.orchestrator_checksum.result.hex}" : "gcs::https://www.googleapis.com/storage/v1/${var.fc_env_pipeline_bucket_name}/orchestrator"
}

module "orchestrator" {
  source = "../../modules/job-orchestrator"

  provider_name = "gcp"
  provider_gcp_config = {
    gcs_grpc_connection_pool_size = var.gcs_grpc_connection_pool_size
  }

  node_pool  = var.orchestrator_node_pool
  port       = var.orchestrator_port
  proxy_port = var.orchestrator_proxy_port

  environment           = var.environment
  artifact_source       = local.orchestrator_artifact_source
  orchestrator_checksum = data.external.orchestrator_checksum.result.hex

  envd_timeout            = var.envd_timeout
  template_bucket_name    = var.template_bucket_name
  build_cache_bucket_name = var.build_cache_bucket_name
  allow_sandbox_internet  = var.allow_sandbox_internet
  redis_url               = local.redis_url
  redis_cluster_url       = local.redis_cluster_url
  redis_tls_ca_base64     = local.redis_tls_ca_base64

  consul_token = var.consul_acl_token_secret
  domain_name  = var.domain_name

  job_env_vars = var.orchestrator_env_vars
}

data "google_storage_bucket_object" "template_manager" {
  name   = "template-manager"
  bucket = var.fc_env_pipeline_bucket_name
}

data "external" "template_manager" {
  program = ["bash", "${path.module}/scripts/checksum.sh"]

  query = {
    base64 = data.google_storage_bucket_object.template_manager.md5hash
  }
}

data "google_storage_bucket_object" "nomad_nodepool_apm" {
  count = var.template_manages_clusters_size_gt_1 ? 1 : 0

  name   = "nomad-nodepool-apm"
  bucket = var.fc_env_pipeline_bucket_name
}

data "external" "nomad_nodepool_apm_checksum" {
  count = var.template_manages_clusters_size_gt_1 ? 1 : 0

  program = ["bash", "${path.module}/scripts/checksum.sh"]

  query = {
    base64 = data.google_storage_bucket_object.nomad_nodepool_apm[0].md5hash
  }
}

module "template_manager" {
  source = "../../modules/job-template-manager"

  provider_name = "gcp"
  provider_gcp_config = {
    project_id                    = var.gcp_project_id
    region                        = var.gcp_region
    docker_registry               = var.custom_envs_repository_name
    gcs_grpc_connection_pool_size = var.gcs_grpc_connection_pool_size
  }

  update_stanza = var.template_manages_clusters_size_gt_1
  node_pool     = var.builder_node_pool

  port             = var.template_manager_port
  environment      = var.environment
  consul_acl_token = var.consul_acl_token_secret
  domain_name      = var.domain_name

  api_secret                = var.api_secret
  artifact_source           = "gcs::https://www.googleapis.com/storage/v1/${var.fc_env_pipeline_bucket_name}/template-manager"
  template_manager_checksum = data.external.template_manager.result.hex
  template_bucket_name      = var.template_bucket_name
  build_cache_bucket_name   = var.build_cache_bucket_name

  nomad_addr  = "http://nomad.${var.domain_name}"
  nomad_token = var.nomad_acl_token_secret
}

module "template_manager_autoscaler" {
  source = "../../modules/job-template-manager-autoscaler"
  count  = var.template_manages_clusters_size_gt_1 ? 1 : 0

  node_pool                  = var.api_node_pool
  autoscaler_version         = var.nomad_autoscaler_version
  nomad_token                = var.nomad_acl_token_secret
  apm_plugin_artifact_source = "gcs::https://www.googleapis.com/storage/v1/${var.fc_env_pipeline_bucket_name}/nomad-nodepool-apm"
  apm_plugin_checksum        = data.external.nomad_nodepool_apm_checksum[0].result.hex
}
