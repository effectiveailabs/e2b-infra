terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.50.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  name_prefix = "e2b-${var.environment}"
  prefix      = "${local.name_prefix}-"
  domain_name = "sandbox.e2b.${var.environment}.internal"

  common_labels = merge(
    {
      application = "e2b"
      environment = var.environment
      managed_by  = "terraform"
      owner       = "effectiveai"
    },
    var.labels,
  )

  enabled_services = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "osconfig.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
  ])

  template_bucket_name       = coalesce(var.template_bucket_name, "effectiveai-e2b-${var.environment}-templates-${var.project_number}")
  docker_context_bucket_name = "effectiveai-e2b-${var.environment}-docker-contexts-${var.project_number}"
  env_pipeline_bucket_name   = coalesce(var.env_pipeline_bucket_name, "effectiveai-e2b-${var.environment}-env-pipeline-${var.project_number}")
  setup_bucket_name          = coalesce(var.setup_bucket_name, "effectiveai-e2b-${var.environment}-instance-setup-${var.project_number}")
  fc_kernels_bucket_name     = "effectiveai-e2b-${var.environment}-fc-kernels-${var.project_number}"
  fc_versions_bucket_name    = "effectiveai-e2b-${var.environment}-fc-versions-${var.project_number}"
  build_cache_bucket_name    = "effectiveai-e2b-${var.environment}-build-cache-${var.project_number}"
  state_bucket_name          = var.state_bucket_name

  build_clusters_config = {
    default = {
      cluster_size = var.build_target_size
      machine = {
        type             = var.build_machine_type
        min_cpu_platform = var.build_min_cpu_platform
      }
      boot_disk = {
        disk_type = var.node_disk_type
        size_gb   = var.build_boot_disk_size_gb
      }
      cache_disks = {
        disk_type = var.build_cache_disk_type
        size_gb   = var.build_cache_disk_size_gb
        count     = var.build_cache_disk_count
      }
      autoscaler             = null
      hugepages_percentage   = var.build_hugepages_percentage
      network_interface_type = null
      node_labels            = []
    }
  }

  client_clusters_config = {
    default = {
      cluster_size = var.client_target_size
      machine = {
        type             = var.client_machine_type
        min_cpu_platform = var.client_min_cpu_platform
      }
      boot_disk = {
        disk_type = var.node_disk_type
        size_gb   = var.client_boot_disk_size_gb
      }
      cache_disks = {
        disk_type = var.client_cache_disk_type
        size_gb   = var.client_cache_disk_size_gb
        count     = var.client_cache_disk_count
      }
      autoscaler = {
        size_max      = var.client_max_size
        cpu_target    = var.client_cpu_target
        memory_target = var.client_memory_target
      }
      hugepages_percentage   = var.client_hugepages_percentage
      network_interface_type = null
      node_labels            = []
    }
  }

  template_manages_clusters_size_gt_1 = alltrue([for c in values(local.build_clusters_config) : c.cluster_size > 1])
}

resource "google_project_service" "enabled" {
  for_each = local.enabled_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

module "init" {
  source = "./init"

  environment    = var.environment
  labels         = local.common_labels
  prefix         = local.prefix
  project_number = var.project_number

  gcp_project_id = var.project_id
  gcp_region     = var.region

  template_bucket_location    = var.region
  template_bucket_name        = local.template_bucket_name
  docker_context_bucket_name  = local.docker_context_bucket_name
  setup_bucket_name           = local.setup_bucket_name
  fc_kernels_bucket_name      = local.fc_kernels_bucket_name
  fc_versions_bucket_name     = local.fc_versions_bucket_name
  fc_env_pipeline_bucket_name = local.env_pipeline_bucket_name
  build_cache_bucket_name     = local.build_cache_bucket_name
  core_repository_id          = var.core_repository_id

  depends_on = [google_project_service.enabled]
}

module "cluster" {
  source = "./nomad-cluster"

  environment = var.environment

  gcp_project_id  = var.project_id
  gcp_region      = var.region
  gcp_zone        = var.zone
  network_name    = var.network_name
  subnetwork_name = var.subnetwork_name

  build_clusters_config  = local.build_clusters_config
  client_clusters_config = local.client_clusters_config

  api_cluster_size    = var.api_target_size
  server_cluster_size = var.server_target_size

  server_machine_type = var.server_machine_type
  api_machine_type    = var.api_machine_type

  api_node_pool          = var.api_node_pool
  build_node_pool        = var.build_node_pool
  orchestrator_node_pool = var.orchestrator_node_pool

  client_proxy_port         = var.client_proxy_port
  client_proxy_health_port  = var.client_proxy_health_port
  ingress_port              = var.ingress_port
  api_port                  = var.api_port
  docker_reverse_proxy_port = var.docker_reverse_proxy_port
  nomad_port                = var.nomad_http_port

  google_service_account_email = module.init.service_account_email
  domain_name                  = local.domain_name
  additional_domains           = []

  docker_contexts_bucket_name = module.init.envs_docker_context_bucket_name
  cluster_setup_bucket_name   = module.init.cluster_setup_bucket_name
  fc_env_pipeline_bucket_name = module.init.fc_env_pipeline_bucket_name
  fc_kernels_bucket_name      = module.init.fc_kernels_bucket_name
  fc_versions_bucket_name     = module.init.fc_versions_bucket_name

  consul_acl_token_secret = module.init.consul_acl_token_secret
  nomad_acl_token_secret  = module.init.nomad_acl_token_secret

  labels                                  = local.common_labels
  prefix                                  = local.prefix
  cluster_tag_name                        = var.cluster_tag_name
  proxy_only_subnet_cidr                  = var.proxy_only_subnet_cidr
  additional_api_paths_handled_by_ingress = var.additional_api_paths_handled_by_ingress

  api_boot_disk_type       = var.node_disk_type
  server_boot_disk_type    = var.node_disk_type
  server_boot_disk_size_gb = var.server_boot_disk_size_gb

  skip_project_iam_grants = false

  depends_on = [module.init]
}

module "nomad" {
  source = "./nomad"

  prefix         = local.prefix
  gcp_project_id = var.project_id
  gcp_region     = var.region
  gcp_zone       = var.zone

  consul_acl_token_secret = module.init.consul_acl_token_secret
  nomad_acl_token_secret  = module.init.nomad_acl_token_secret
  nomad_port              = var.nomad_http_port
  core_repository_name    = module.init.core_repository_name

  ingress_port                 = var.ingress_port
  ingress_count                = var.ingress_count
  additional_traefik_arguments = var.additional_traefik_arguments

  api_server_count                                       = var.api_server_count
  api_resources_cpu_count                                = var.api_resources_cpu_count
  api_resources_memory_mb                                = var.api_resources_memory_mb
  api_machine_count                                      = var.api_target_size
  api_node_pool                                          = var.api_node_pool
  api_port                                               = var.api_port
  environment                                            = var.environment
  api_secret                                             = random_password.api_secret.result
  custom_envs_repository_name                            = google_artifact_registry_repository.custom_environments_repository.name
  postgres_connection_string_secret_name                 = module.init.postgres_connection_string_secret_name
  postgres_connection_string_secret_version_dependency   = google_secret_manager_secret_version.postgres_connection_string
  postgres_read_replica_connection_string_secret_version = google_secret_manager_secret_version.postgres_read_replica_connection_string
  api_admin_token                                        = random_password.api_admin_secret.result
  sandbox_access_token_hash_seed                         = random_password.sandbox_access_token_hash_seed.result
  sandbox_storage_backend                                = var.sandbox_storage_backend
  db_max_open_connections                                = var.db_max_open_connections
  db_min_idle_connections                                = var.db_min_idle_connections
  auth_db_max_open_connections                           = var.auth_db_max_open_connections
  auth_db_min_idle_connections                           = var.auth_db_min_idle_connections

  client_proxy_count               = var.client_proxy_count
  client_proxy_resources_cpu_count = var.client_proxy_resources_cpu_count
  client_proxy_resources_memory_mb = var.client_proxy_resources_memory_mb
  client_proxy_update_max_parallel = var.client_proxy_update_max_parallel
  client_proxy_session_port        = var.client_proxy_port.port
  client_proxy_health_port         = var.client_proxy_health_port.port

  domain_name = local.domain_name

  docker_reverse_proxy_port = var.docker_reverse_proxy_port

  orchestrator_node_pool      = var.orchestrator_node_pool
  allow_sandbox_internet      = var.allow_sandbox_internet
  orchestrator_port           = var.orchestrator_port
  orchestrator_proxy_port     = var.orchestrator_proxy_port
  fc_env_pipeline_bucket_name = module.init.fc_env_pipeline_bucket_name
  envd_timeout                = var.envd_timeout
  orchestrator_env_vars       = var.orchestrator_env_vars
  loki_url                    = var.loki_url

  builder_node_pool                   = var.build_node_pool
  template_manager_port               = var.template_manager_port
  template_bucket_name                = module.init.fc_template_bucket_name
  build_cache_bucket_name             = module.init.fc_build_cache_bucket_name
  template_manages_clusters_size_gt_1 = local.template_manages_clusters_size_gt_1

  redis_port = var.redis_port

  gcs_grpc_connection_pool_size = var.gcs_grpc_connection_pool_size
}
