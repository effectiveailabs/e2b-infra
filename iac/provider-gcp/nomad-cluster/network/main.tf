locals {
  backends = {
    session = {
      port_name = var.client_proxy_port.name
      port      = var.client_proxy_health_port.port
      path      = var.client_proxy_health_port.path
      group     = var.api_instance_group
    }
    api = {
      port_name = var.api_port.name
      port      = var.api_port.port
      path      = var.api_port.health_path
      group     = var.api_instance_group
    }
    docker_reverse_proxy = {
      port_name = var.docker_reverse_proxy_port.name
      port      = var.docker_reverse_proxy_port.port
      path      = var.docker_reverse_proxy_port.health_path
      group     = var.api_instance_group
    }
    nomad = {
      port_name = "nomad"
      port      = var.nomad_port
      path      = "/v1/status/peers"
      group     = var.server_instance_group
    }
    ingress = {
      port_name = var.ingress_port.name
      port      = var.ingress_port.port
      path      = var.ingress_port.health_path
      group     = var.api_instance_group
    }
  }
}

data "google_compute_network" "main" {
  name    = var.network_name
  project = var.gcp_project_id
}

data "google_compute_subnetwork" "main" {
  name    = var.subnetwork_name
  region  = var.gcp_region
  project = var.gcp_project_id
}

resource "google_compute_subnetwork" "proxy_only" {
  name          = "${var.prefix}proxy-only"
  ip_cidr_range = var.proxy_only_subnet_cidr
  region        = var.gcp_region
  network       = data.google_compute_network.main.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_address" "internal_lb" {
  name         = "${var.prefix}internal-lb"
  subnetwork   = data.google_compute_subnetwork.main.id
  address_type = "INTERNAL"
  region       = var.gcp_region
  purpose      = "GCE_ENDPOINT"
}

resource "google_dns_managed_zone" "sandbox_internal" {
  name        = "e2b-sandbox-${var.environment}"
  dns_name    = "${var.domain_name}."
  description = "Private DNS zone for E2B sandbox routing (${var.environment})"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.main.id
    }
  }
}

resource "google_dns_record_set" "sandbox_wildcard" {
  name         = "*.${google_dns_managed_zone.sandbox_internal.dns_name}"
  type         = "A"
  ttl          = 60
  managed_zone = google_dns_managed_zone.sandbox_internal.name
  rrdatas      = [google_compute_address.internal_lb.address]
}

resource "google_compute_region_health_check" "default" {
  for_each = local.backends

  name   = "${var.prefix}hc-${replace(each.key, "_", "-")}"
  region = var.gcp_region

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = each.value.port
    request_path = each.value.path
  }
}

resource "google_compute_region_backend_service" "default" {
  for_each = local.backends

  name                  = "${var.prefix}backend-${replace(each.key, "_", "-")}"
  region                = var.gcp_region
  port_name             = lookup(each.value, "port_name", "http")
  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.default[each.key].id]
  timeout_sec           = each.key == "session" ? 86400 : 80

  backend {
    group           = each.value.group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  log_config {
    enable = true
  }
}

resource "google_compute_region_url_map" "default" {
  name            = "${var.prefix}url-map"
  region          = var.gcp_region
  default_service = google_compute_region_backend_service.default["session"].id

  host_rule {
    hosts        = ["api.${var.domain_name}"]
    path_matcher = "api-paths"
  }

  host_rule {
    hosts        = ["docker.${var.domain_name}"]
    path_matcher = "docker-paths"
  }

  host_rule {
    hosts        = ["nomad.${var.domain_name}"]
    path_matcher = "nomad-paths"
  }

  host_rule {
    hosts        = ["*.${var.domain_name}"]
    path_matcher = "session-paths"
  }

  path_matcher {
    name            = "api-paths"
    default_service = google_compute_region_backend_service.default["api"].id

    dynamic "path_rule" {
      for_each = length(var.additional_api_paths_handled_by_ingress) > 0 ? [1] : []
      content {
        paths   = var.additional_api_paths_handled_by_ingress
        service = google_compute_region_backend_service.default["ingress"].id
      }
    }
  }

  path_matcher {
    name            = "docker-paths"
    default_service = google_compute_region_backend_service.default["docker_reverse_proxy"].id
  }

  path_matcher {
    name            = "nomad-paths"
    default_service = google_compute_region_backend_service.default["nomad"].id
  }

  path_matcher {
    name            = "ingress-paths"
    default_service = google_compute_region_backend_service.default["ingress"].id
  }

  path_matcher {
    name            = "session-paths"
    default_service = google_compute_region_backend_service.default["session"].id
  }
}

resource "google_compute_region_target_http_proxy" "default" {
  name    = "${var.prefix}http-proxy"
  region  = var.gcp_region
  url_map = google_compute_region_url_map.default.id
}

resource "google_compute_forwarding_rule" "default" {
  name                  = "${var.prefix}http-forwarding-rule"
  region                = var.gcp_region
  load_balancing_scheme = "INTERNAL_MANAGED"
  target                = google_compute_region_target_http_proxy.default.id
  ip_protocol           = "TCP"
  port_range            = "80"
  network               = data.google_compute_network.main.id
  subnetwork            = data.google_compute_subnetwork.main.id
  ip_address            = google_compute_address.internal_lb.address
  allow_global_access   = true

  depends_on = [google_compute_subnetwork.proxy_only]
}

resource "google_compute_firewall" "load_balancer_health_checks" {
  name    = "${var.prefix}load-balancer-hc"
  network = data.google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports = [
      tostring(var.client_proxy_health_port.port),
      tostring(var.api_port.port),
      tostring(var.docker_reverse_proxy_port.port),
      tostring(var.ingress_port.port),
      tostring(var.nomad_port),
    ]
  }

  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = [var.cluster_tag_name]
}

resource "google_compute_firewall" "proxy_subnet_to_backends" {
  name    = "${var.prefix}proxy-only-to-backends"
  network = data.google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports = [
      tostring(var.client_proxy_port.port),
      tostring(var.client_proxy_health_port.port),
      tostring(var.api_port.port),
      tostring(var.docker_reverse_proxy_port.port),
      tostring(var.ingress_port.port),
      tostring(var.nomad_port),
    ]
  }

  direction     = "INGRESS"
  source_ranges = [google_compute_subnetwork.proxy_only.ip_cidr_range]
  target_tags   = [var.cluster_tag_name]
}

resource "google_compute_firewall" "internal_remote_connection_firewall_ingress" {
  name    = "${var.prefix}${var.cluster_tag_name}-internal-remote-fw-ingress"
  network = data.google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389", "${var.nomad_port}"]
  }

  priority      = 900
  direction     = "INGRESS"
  target_tags   = [var.cluster_tag_name]
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "remote_connection_firewall_ingress" {
  name    = "${var.prefix}${var.cluster_tag_name}-remote-fw-ingress"
  network = data.google_compute_network.main.name

  deny {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  priority      = 1000
  direction     = "INGRESS"
  target_tags   = [var.cluster_tag_name]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "orch_firewall_egress" {
  name    = "${var.prefix}${var.cluster_tag_name}-fw-egress"
  network = data.google_compute_network.main.name

  allow { protocol = "all" }

  direction   = "EGRESS"
  target_tags = [var.cluster_tag_name]
}

# Allow all internal traffic between cluster nodes (Consul gossip, Nomad RPC, etc.)
# The default VPC has default-allow-internal, but custom VPCs like 'dev' do not.
resource "google_compute_firewall" "cluster_internal_allow_all" {
  name    = "${var.prefix}${var.cluster_tag_name}-internal-allow-all"
  network = data.google_compute_network.main.name

  allow { protocol = "tcp" }
  allow { protocol = "udp" }

  direction   = "INGRESS"
  source_tags = [var.cluster_tag_name]
  target_tags = [var.cluster_tag_name]
}
