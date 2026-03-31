variable "provider_name" {
  type        = string
  description = "Cloud provider: gcp or aws"

  validation {
    condition     = contains(["gcp", "aws"], var.provider_name)
    error_message = "provider_name must be 'gcp' or 'aws'"
  }
}

variable "provider_aws_config" {
  type = object({
    region                 = string
    docker_repository_name = string
  })
  default = {
    region                 = ""
    docker_repository_name = ""
  }
}

variable "provider_gcp_config" {
  type = object({
    service_account_key           = optional(string, "")
    gcs_grpc_connection_pool_size = optional(number, 0)
  })
  default = {
    service_account_key           = ""
    gcs_grpc_connection_pool_size = 0
  }
}

variable "node_pool" { type = string }
variable "port" { type = number }
variable "proxy_port" { type = number }
variable "environment" { type = string }
variable "artifact_source" { type = string }
variable "orchestrator_checksum" { type = string }
variable "envd_timeout" { type = string }
variable "template_bucket_name" { type = string }
variable "allow_sandbox_internet" { type = bool }

variable "redis_url" {
  type      = string
  sensitive = true
}

variable "redis_cluster_url" {
  type      = string
  sensitive = true
}

variable "redis_tls_ca_base64" {
  type      = string
  default   = ""
  sensitive = true
}

variable "redis_pool_size" {
  type    = number
  default = 10
}

variable "consul_token" {
  type      = string
  sensitive = true
}

variable "domain_name" { type = string }

variable "orchestrator_services" {
  type    = string
  default = "orchestrator"
}

variable "build_cache_bucket_name" {
  type    = string
  default = ""
}

variable "use_local_namespace_storage" {
  type    = bool
  default = false
}

variable "job_env_vars" {
  type    = map(string)
  default = {}
}
