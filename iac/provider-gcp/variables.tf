variable "environment" {
  description = "Logical environment label for the E2B deployment."
  type        = string
  default     = "prod"
}

variable "project_id" {
  description = "GCP project ID."
  type        = string
  default     = "gen-lang-client-0802504039"
}

variable "project_number" {
  description = "Numeric GCP project number."
  type        = string
  default     = "487957898723"
}

variable "region" {
  description = "Primary GCP region."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Primary GCP zone."
  type        = string
  default     = "us-central1-a"
}

variable "labels" {
  description = "Additional labels to apply to resources."
  type        = map(string)
  default     = {}
}

variable "network_name" {
  description = "Name of the shared VPC network to attach to."
  type        = string
}

variable "subnetwork_name" {
  description = "Name of the existing subnet used by E2B workloads."
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the Terraform remote state bucket."
  type        = string
  default     = "effectiveai-e2b-terraform-state"
}

variable "template_bucket_name" {
  description = "Optional override for the template bucket name."
  type        = string
  default     = null
  nullable    = true
}

variable "env_pipeline_bucket_name" {
  description = "Optional override for the env pipeline bucket name."
  type        = string
  default     = null
  nullable    = true
}

variable "setup_bucket_name" {
  description = "Optional override for the instance setup bucket name."
  type        = string
  default     = null
  nullable    = true
}

variable "core_repository_id" {
  description = "Shared Artifact Registry repository containing core E2B images."
  type        = string
  default     = "e2b-core"
}

variable "node_disk_type" {
  description = "Persistent disk type for node boot disks."
  type        = string
  default     = "pd-ssd"
}

variable "server_machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "server_target_size" {
  type    = number
  default = 3
}

variable "server_boot_disk_size_gb" {
  type    = number
  default = 20
}

variable "api_machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "api_target_size" {
  type    = number
  default = 1
}

variable "build_machine_type" {
  type    = string
  default = "n2-standard-4"
}

variable "build_min_cpu_platform" {
  type    = string
  default = "Intel Skylake"
}

variable "build_target_size" {
  type    = number
  default = 1
}

variable "build_boot_disk_size_gb" {
  type    = number
  default = 200
}

variable "build_cache_disk_type" {
  type    = string
  default = "pd-ssd"
}

variable "build_cache_disk_size_gb" {
  type    = number
  default = 375
}

variable "build_cache_disk_count" {
  type    = number
  default = 1
}

variable "build_hugepages_percentage" {
  type    = number
  default = 60
}

variable "client_machine_type" {
  type    = string
  default = "n2-standard-16"
}

variable "client_min_cpu_platform" {
  type    = string
  default = "Intel Skylake"
}

variable "client_target_size" {
  type    = number
  default = 4
}

variable "client_max_size" {
  type    = number
  default = 16
}

variable "client_boot_disk_size_gb" {
  type    = number
  default = 500
}

variable "client_cache_disk_type" {
  type    = string
  default = "pd-ssd"
}

variable "client_cache_disk_size_gb" {
  type    = number
  default = 375
}

variable "client_cache_disk_count" {
  type    = number
  default = 1
}

variable "client_hugepages_percentage" {
  type    = number
  default = 80
}

variable "client_cpu_target" {
  type    = number
  default = 0.7
}

variable "client_memory_target" {
  type    = number
  default = 95
}

variable "db_instance_name" {
  type    = string
  default = ""
}

variable "db_name" {
  type    = string
  default = "e2b"
}

variable "db_user" {
  type    = string
  default = "e2b"
}

variable "db_tier" {
  type    = string
  default = "db-custom-2-7680"
}

variable "db_availability_type" {
  type    = string
  default = "REGIONAL"
}

variable "db_disk_size_gb" {
  type    = number
  default = 100
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "proxy_only_subnet_cidr" {
  description = "CIDR range for the regional proxy-only subnet used by the internal HTTP load balancer."
  type        = string
  default     = "10.129.0.0/23"
}

variable "cluster_tag_name" {
  type    = string
  default = "e2b-node"
}

variable "api_node_pool" {
  type    = string
  default = "api"
}

variable "build_node_pool" {
  type    = string
  default = "build"
}

variable "orchestrator_node_pool" {
  type    = string
  default = "default"
}

variable "api_port" {
  type = object({
    name        = string
    port        = number
    health_path = string
  })
  default = {
    name        = "api"
    port        = 50001
    health_path = "/health"
  }
}

variable "ingress_port" {
  type = object({
    name        = string
    port        = number
    health_path = string
  })
  default = {
    name        = "ingress"
    port        = 8800
    health_path = "/ping"
  }
}

variable "docker_reverse_proxy_port" {
  type = object({
    name        = string
    port        = number
    health_path = string
  })
  default = {
    name        = "docker-reverse-proxy"
    port        = 5000
    health_path = "/health"
  }
}

variable "client_proxy_health_port" {
  type = object({
    name = string
    port = number
    path = string
  })
  default = {
    name = "client-proxy"
    port = 3001
    path = "/health"
  }
}

variable "client_proxy_port" {
  type = object({
    name = string
    port = number
  })
  default = {
    name = "session"
    port = 3002
  }
}

variable "nomad_http_port" {
  type    = number
  default = 4646
}

variable "redis_port" {
  type = object({
    name = string
    port = number
  })
  default = {
    name = "redis"
    port = 6379
  }
}

variable "ingress_count" {
  type    = number
  default = 1
}

variable "additional_api_paths_handled_by_ingress" {
  type    = list(string)
  default = []
}

variable "additional_traefik_arguments" {
  type    = list(string)
  default = []
}

variable "api_server_count" {
  type    = number
  default = 1
}

variable "api_resources_cpu_count" {
  type    = number
  default = 2
}

variable "api_resources_memory_mb" {
  type    = number
  default = 2048
}

variable "client_proxy_count" {
  type    = number
  default = 1
}

variable "client_proxy_resources_cpu_count" {
  type    = number
  default = 1
}

variable "client_proxy_resources_memory_mb" {
  type    = number
  default = 1024
}

variable "client_proxy_update_max_parallel" {
  type    = number
  default = 1
}

variable "allow_sandbox_internet" {
  type    = bool
  default = true
}

variable "orchestrator_port" {
  type    = number
  default = 5008
}

variable "orchestrator_proxy_port" {
  type    = number
  default = 5007
}

variable "template_manager_port" {
  type    = number
  default = 5008
}

variable "envd_timeout" {
  type    = string
  default = "40s"
}

variable "sandbox_storage_backend" {
  type    = string
  default = "memory"
}

variable "db_max_open_connections" {
  type    = number
  default = 40
}

variable "db_min_idle_connections" {
  type    = number
  default = 5
}

variable "auth_db_max_open_connections" {
  type    = number
  default = 20
}

variable "auth_db_min_idle_connections" {
  type    = number
  default = 5
}

variable "gcs_grpc_connection_pool_size" {
  type    = number
  default = 0
}

variable "orchestrator_env_vars" {
  type    = map(string)
  default = {}
}
