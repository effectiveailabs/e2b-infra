data "google_compute_network" "main" {
  name    = var.network_name
  project = var.project_id
}

data "google_compute_subnetwork" "main" {
  name    = var.subnetwork_name
  region  = var.region
  project = var.project_id
}
