variable "prefix" { type = string }
variable "environment" { type = string }
variable "domain_name" { type = string }
variable "additional_domains" { type = list(string) }
variable "cluster_tag_name" { type = string }
variable "network_name" { type = string }
variable "subnetwork_name" { type = string }
variable "gcp_project_id" { type = string }
variable "gcp_region" { type = string }
variable "api_port" {
  type = object({ name = string, port = number, health_path = string })
}
variable "ingress_port" {
  type = object({ name = string, port = number, health_path = string })
}
variable "docker_reverse_proxy_port" {
  type = object({ name = string, port = number, health_path = string })
}
variable "client_proxy_health_port" {
  type = object({ name = string, port = number, path = string })
}
variable "client_proxy_port" {
  type = object({ name = string, port = number })
}
variable "nomad_port" { type = number }
variable "api_instance_group" { type = string }
variable "server_instance_group" { type = string }
variable "labels" { type = map(string) }
variable "additional_api_paths_handled_by_ingress" { type = list(string) }
variable "proxy_only_subnet_cidr" { type = string }
