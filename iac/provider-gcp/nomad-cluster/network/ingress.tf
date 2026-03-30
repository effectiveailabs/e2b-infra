resource "google_compute_health_check" "ingress" {
  name = "${var.prefix}ingress"

  timeout_sec         = 3
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = var.ingress_port.port
    request_path = var.ingress_port.health_path
  }
}

resource "google_compute_security_policy" "ingress" {
  name = "${var.prefix}ingress"

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}

resource "google_compute_region_backend_service" "ingress" {
  name   = "${var.prefix}ingress"
  region = var.gcp_region

  protocol         = "HTTP"
  port_name        = var.ingress_port.name
  session_affinity = null
  health_checks    = [google_compute_health_check.ingress.id]
  timeout_sec      = 80

  load_balancing_scheme = "INTERNAL_MANAGED"
  locality_lb_policy    = "ROUND_ROBIN"


  backend {
    group = var.api_instance_group
  }
}
