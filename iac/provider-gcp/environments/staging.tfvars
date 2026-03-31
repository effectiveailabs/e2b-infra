environment     = "staging"
network_name    = "dev"
subnetwork_name = "dev"

# Staging overrides: smaller footprint, cheaper, easier teardown
client_target_size     = 1
client_max_size        = 2
server_target_size     = 1

# E2 instances don't support onHostMaintenance=TERMINATE (required by
# the nested-virt license on the e2b-orch image). Use N1 instead.
server_machine_type = "n1-standard-2"
api_machine_type    = "n1-standard-2"

# N2 machines require Cascade Lake or newer in us-central1.
build_min_cpu_platform  = "Intel Cascade Lake"
client_min_cpu_platform = "Intel Cascade Lake"
db_availability_type   = "ZONAL"
db_deletion_protection = false
