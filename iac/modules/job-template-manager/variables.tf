variable "provider_name" {
  type        = string
  description = "Cloud provider: gcp or aws"

  validation {
    condition     = contains(["gcp", "aws"], var.provider_name)
    error_message = "provider_name must be 'gcp' or 'aws'"
  }
}

variable "provider_gcp_config" {
  type = object({
    service_account_key           = optional(string, "")
    project_id                    = optional(string, "")
    region                        = optional(string, "")
    docker_registry               = optional(string, "")
    gcs_grpc_connection_pool_size = optional(number, 0)
  })
  default = {
    service_account_key           = ""
    project_id                    = ""
    region                        = ""
    docker_registry               = ""
    gcs_grpc_connection_pool_size = 0
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

variable "node_pool" { type = string }
variable "port" { type = number }
variable "environment" { type = string }
variable "domain_name" { type = string }
variable "update_stanza" { type = bool }
variable "artifact_source" { type = string }
variable "template_manager_checksum" { type = string }

variable "api_secret" {
  type      = string
  sensitive = true
}

variable "consul_acl_token" {
  type      = string
  sensitive = true
}

variable "template_bucket_name" { type = string }

variable "build_cache_bucket_name" {
  type    = string
  default = ""
}

variable "orchestrator_services" {
  type    = string
  default = "template-manager"
}

variable "redis_pool_size" {
  type    = number
  default = 10
}

variable "nomad_addr" { type = string }

variable "nomad_token" {
  type      = string
  sensitive = true
}
