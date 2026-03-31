locals {
  build_base_hugepages_percentage  = 60
  client_base_hugepages_percentage = 80

  file_hash = {
    "scripts/run-consul.sh" = substr(filesha256("${path.module}/scripts/run-consul.sh"), 0, 5)
    "scripts/run-nomad.sh"  = substr(filesha256("${path.module}/scripts/run-nomad.sh"), 0, 5)
  }
}

resource "google_secret_manager_secret" "consul_gossip_encryption_key" {
  secret_id = "${var.prefix}consul-gossip-key"

  replication {
    auto {}
  }
}

resource "random_id" "consul_gossip_encryption_key" {
  byte_length = 32
}

resource "google_secret_manager_secret_version" "consul_gossip_encryption_key" {
  secret      = google_secret_manager_secret.consul_gossip_encryption_key.name
  secret_data = random_id.consul_gossip_encryption_key.b64_std
}

resource "google_secret_manager_secret" "consul_dns_request_token" {
  secret_id = "${var.prefix}consul-dns-request-token"

  replication {
    auto {}
  }
}

resource "random_uuid" "consul_dns_request_token" {}

resource "google_secret_manager_secret_version" "consul_dns_request_token" {
  secret      = google_secret_manager_secret.consul_dns_request_token.name
  secret_data = random_uuid.consul_dns_request_token.result
}

resource "google_project_iam_member" "network_viewer" {
  count   = var.skip_project_iam_grants ? 0 : 1
  project = var.gcp_project_id
  member  = "serviceAccount:${var.google_service_account_email}"
  role    = "roles/compute.networkViewer"
}

resource "google_project_iam_member" "monitoring_editor" {
  count   = var.skip_project_iam_grants ? 0 : 1
  project = var.gcp_project_id
  member  = "serviceAccount:${var.google_service_account_email}"
  role    = "roles/monitoring.editor"
}

resource "google_project_iam_member" "logging_writer" {
  count   = var.skip_project_iam_grants ? 0 : 1
  project = var.gcp_project_id
  member  = "serviceAccount:${var.google_service_account_email}"
  role    = "roles/logging.logWriter"
}

variable "setup_files" {
  type = map(string)
  default = {
    "scripts/run-nomad.sh"  = "run-nomad"
    "scripts/run-consul.sh" = "run-consul"
  }
}

resource "google_storage_bucket_object" "setup_config_objects" {
  for_each = var.setup_files
  name     = "${each.value}-${local.file_hash[each.key]}.sh"
  source   = "${path.module}/${each.key}"
  bucket   = var.cluster_setup_bucket_name
}

module "network" {
  source = "./network"

  environment    = var.environment
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region

  ingress_port                            = var.ingress_port
  api_port                                = var.api_port
  docker_reverse_proxy_port               = var.docker_reverse_proxy_port
  network_name                            = var.network_name
  subnetwork_name                         = var.subnetwork_name
  domain_name                             = var.domain_name
  additional_domains                      = var.additional_domains
  additional_api_paths_handled_by_ingress = var.additional_api_paths_handled_by_ingress
  proxy_only_subnet_cidr                  = var.proxy_only_subnet_cidr

  client_proxy_port        = var.client_proxy_port
  client_proxy_health_port = var.client_proxy_health_port

  api_instance_group    = google_compute_instance_group_manager.api_pool.instance_group
  server_instance_group = google_compute_region_instance_group_manager.server_pool.instance_group

  nomad_port       = var.nomad_port
  cluster_tag_name = var.cluster_tag_name
  labels           = var.labels
  prefix           = var.prefix
}

module "build_cluster" {
  for_each = var.build_clusters_config
  source   = "./worker-cluster"

  gcp_region                   = var.gcp_region
  gcp_zone                     = var.gcp_zone
  google_service_account_email = var.google_service_account_email

  cluster_size     = each.value.cluster_size
  cache_disks      = each.value.cache_disks
  machine_type     = each.value.machine.type
  min_cpu_platform = each.value.machine.min_cpu_platform
  boot_disk        = each.value.boot_disk
  autoscaler       = each.value.autoscaler

  cluster_name              = "${var.prefix}${var.build_cluster_name}-${each.key}"
  image_family              = var.build_image_family
  network_name              = var.network_name
  subnetwork_name           = var.subnetwork_name
  base_hugepages_percentage = coalesce(each.value.hugepages_percentage, local.build_base_hugepages_percentage)
  network_interface_type    = each.value.network_interface_type
  node_labels               = each.value.node_labels

  cluster_tag_name                         = var.cluster_tag_name
  node_pool                                = var.build_node_pool
  nomad_port                               = var.nomad_port
  consul_acl_token_secret                  = var.consul_acl_token_secret
  nomad_acl_token_secret                   = var.nomad_acl_token_secret
  consul_gossip_encryption_key_secret_data = google_secret_manager_secret_version.consul_gossip_encryption_key.secret_data
  consul_dns_request_token_secret_data     = google_secret_manager_secret_version.consul_dns_request_token.secret_data

  docker_contexts_bucket_name = var.docker_contexts_bucket_name
  cluster_setup_bucket_name   = var.cluster_setup_bucket_name
  fc_env_pipeline_bucket_name = var.fc_env_pipeline_bucket_name
  fc_kernels_bucket_name      = var.fc_kernels_bucket_name
  fc_versions_bucket_name     = var.fc_versions_bucket_name

  filestore_cache_enabled = false
  nfs_ip_addresses        = []
  nfs_mount_path          = ""
  nfs_mount_subdir        = ""
  nfs_mount_opts          = ""
  persistent_volume_types = {}

  environment = var.environment
  labels      = var.labels

  file_hash = local.file_hash

  set_orchestrator_version_metadata = false

  depends_on = [
    google_storage_bucket_object.setup_config_objects["scripts/run-nomad.sh"],
    google_storage_bucket_object.setup_config_objects["scripts/run-consul.sh"],
  ]
}

module "client_cluster" {
  for_each = var.client_clusters_config
  source   = "./worker-cluster"

  gcp_region                   = var.gcp_region
  gcp_zone                     = var.gcp_zone
  google_service_account_email = var.google_service_account_email

  cluster_size     = each.value.cluster_size
  cache_disks      = each.value.cache_disks
  machine_type     = each.value.machine.type
  min_cpu_platform = each.value.machine.min_cpu_platform
  boot_disk        = each.value.boot_disk
  autoscaler       = each.value.autoscaler

  cluster_name              = each.key == "default" ? "${var.prefix}${var.client_cluster_name}" : "${var.prefix}${var.client_cluster_name}-${each.key}"
  image_family              = var.client_image_family
  network_name              = var.network_name
  subnetwork_name           = var.subnetwork_name
  base_hugepages_percentage = coalesce(each.value.hugepages_percentage, local.client_base_hugepages_percentage)
  network_interface_type    = each.value.network_interface_type
  node_labels               = each.value.node_labels

  cluster_tag_name                         = var.cluster_tag_name
  node_pool                                = var.orchestrator_node_pool
  nomad_port                               = var.nomad_port
  consul_acl_token_secret                  = var.consul_acl_token_secret
  nomad_acl_token_secret                   = var.nomad_acl_token_secret
  consul_gossip_encryption_key_secret_data = google_secret_manager_secret_version.consul_gossip_encryption_key.secret_data
  consul_dns_request_token_secret_data     = google_secret_manager_secret_version.consul_dns_request_token.secret_data

  docker_contexts_bucket_name = var.docker_contexts_bucket_name
  cluster_setup_bucket_name   = var.cluster_setup_bucket_name
  fc_env_pipeline_bucket_name = var.fc_env_pipeline_bucket_name
  fc_kernels_bucket_name      = var.fc_kernels_bucket_name
  fc_versions_bucket_name     = var.fc_versions_bucket_name

  filestore_cache_enabled = false
  nfs_ip_addresses        = []
  nfs_mount_path          = ""
  nfs_mount_subdir        = ""
  nfs_mount_opts          = ""
  persistent_volume_types = {}

  environment = var.environment
  labels      = var.labels

  file_hash = local.file_hash

  set_orchestrator_version_metadata = true

  depends_on = [
    google_storage_bucket_object.setup_config_objects["scripts/run-nomad.sh"],
    google_storage_bucket_object.setup_config_objects["scripts/run-consul.sh"],
  ]
}
