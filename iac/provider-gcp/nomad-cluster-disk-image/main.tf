terraform {
  required_version = ">= 1.5.0, < 1.6.0"
  backend "gcs" {
    prefix = "terraform/cluster-disk-image/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.49.3"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

data "google_compute_network" "packer_network" {
  # EFFECTIVEAI: build the image inside the shared VPC instead of provisioning
  # a throwaway network on every init.
  name = var.network_name
}

data "google_compute_subnetwork" "packer_subnetwork" {
  name   = var.subnetwork_name
  region = var.gcp_region
}


resource "google_compute_firewall" "internal_remote_connection_firewall_ingress" {
  name    = "${var.network_name}-firewall-ingress"
  network = data.google_compute_network.packer_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  priority = 900

  direction = "INGRESS"
  # https://googlecloudplatform.github.io/iap-desktop/setup-iap/
  source_ranges = ["35.235.240.0/20"]
}