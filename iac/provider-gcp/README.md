# E2B Terraform

This directory now contains a trimmed E2B runtime Terraform based on the
upstream `effectiveailabs/e2b-infra` layout, but reduced to the core services we
actually run.

A single root apply still provisions the full stack:

- GCP prerequisites (APIs, buckets, secrets, service account, Cloud SQL)
- Nomad + Consul VMs with the upstream startup scripts
- Internal-only load balancing + private Cloud DNS
- Nomad jobs for the E2B runtime

## Architecture
