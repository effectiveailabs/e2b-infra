variable "environment" { type = string }
variable "prefix" { type = string }
variable "project_number" { type = string }
variable "labels" { type = map(string) }
variable "gcp_project_id" { type = string }
variable "gcp_region" { type = string }
variable "template_bucket_location" { type = string }
variable "template_bucket_name" { type = string }
variable "docker_context_bucket_name" { type = string }
variable "setup_bucket_name" { type = string }
variable "fc_kernels_bucket_name" { type = string }
variable "fc_versions_bucket_name" { type = string }
variable "fc_env_pipeline_bucket_name" { type = string }
variable "build_cache_bucket_name" { type = string }
variable "core_repository_id" {
  type    = string
  default = "e2b-core"
}
