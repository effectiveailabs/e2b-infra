output "sandbox_dns_zone" {
  value = google_dns_managed_zone.sandbox_internal.dns_name
}

output "internal_lb_ip" {
  value = google_compute_address.internal_lb.address
}

output "sandbox_domain" {
  value = trimsuffix(google_dns_managed_zone.sandbox_internal.dns_name, ".")
}
