variable "prefix" {
  type = string
}

variable "environment" {
  description = "The environment (e.g. staging, prod)."
  type        = string
}

variable "cluster_tag_name" {
  description = "The tag name Compute Instances use to discover the cluster."
  type        = string
  default     = "orch"
}

variable "server_image_family" {
  type    = string
  default = "e2b-orch"
}

variable "server_cluster_name" {
  type    = string
  default = "orch-server"
}

variable "server_cluster_size" {
  type = number
}

variable "server_machine_type" {
  type = string
}

variable "api_image_family" {
  type    = string
  default = "e2b-orch"
}

variable "api_cluster_size" {
  type = number
}

variable "api_machine_type" {
  type = string
}

variable "build_image_family" {
  type    = string
  default = "e2b-orch"
}

variable "client_proxy_health_port" {
  type = object({
    name = string
    port = number
    path = string
  })
}

variable "client_proxy_port" {
  type = object({
    name = string
    port = number
  })
}

variable "api_port" {
  type = object({
    name        = string
    port        = number
    health_path = string
  })
}

variable "ingress_port" {
  type = object({
    name        = string
    port        = number
    health_path = string
  })
}

variable "docker_reverse_proxy_port" {
  type = object({
    name        = string
    port        = number
    health_path = string
  })
}

variable "client_image_family" {
  type    = string
  default = "e2b-orch"
}

variable "client_cluster_name" {
  type    = string
  default = "orch-client"
}

variable "client_clusters_config" {
  description = "Client cluster configurations"
  type = map(object({
    cluster_size = number
    autoscaler = optional(object({
      size_max      = optional(number)
      cpu_target    = optional(number)
      memory_target = optional(number)
    }))
    machine = object({
      type             = string
      min_cpu_platform = string
    })
    boot_disk = object({
      disk_type = string
      size_gb   = number
    })
    cache_disks = object({
      disk_type = string
      size_gb   = number
      count     = number
    })
    hugepages_percentage   = optional(number)
    network_interface_type = optional(string)
    node_labels            = optional(list(string), [])
  }))
}

variable "build_cluster_name" {
  type    = string
  default = "orch-build"
}

variable "build_clusters_config" {
  description = "Build cluster configurations"
  type = map(object({
    cluster_size = number
    autoscaler = optional(object({
      size_max      = optional(number)
      cpu_target    = optional(number)
      memory_target = optional(number)
    }))
    machine = object({
      type             = string
      min_cpu_platform = string
    })
    boot_disk = object({
      disk_type = string
      size_gb   = number
    })
    cache_disks = object({
      disk_type = string
      size_gb   = number
      count     = number
    })
    hugepages_percentage   = optional(number)
    network_interface_type = optional(string)
    node_labels            = optional(list(string), [])
  }))
}

variable "gcp_project_id" { type = string }
variable "gcp_region" { type = string }
variable "gcp_zone" { type = string }
variable "network_name" { type = string }
variable "subnetwork_name" { type = string }
variable "google_service_account_email" { type = string }
variable "docker_contexts_bucket_name" { type = string }
variable "domain_name" { type = string }
variable "additional_domains" { type = list(string) }
variable "cluster_setup_bucket_name" { type = string }
variable "fc_env_pipeline_bucket_name" { type = string }
variable "fc_kernels_bucket_name" { type = string }
variable "fc_versions_bucket_name" { type = string }
variable "consul_acl_token_secret" { type = string }
variable "nomad_acl_token_secret" { type = string }
variable "nomad_port" { type = number }
variable "labels" { type = map(string) }
variable "proxy_only_subnet_cidr" { type = string }
variable "api_node_pool" { type = string }
variable "build_node_pool" { type = string }
variable "orchestrator_node_pool" { type = string }
variable "api_boot_disk_type" { type = string }
variable "server_boot_disk_type" { type = string }
variable "server_boot_disk_size_gb" { type = number }
variable "additional_api_paths_handled_by_ingress" { type = list(string) }

variable "skip_project_iam_grants" {
  type    = bool
  default = true
}
