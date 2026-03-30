environment     = "staging"
network_name    = "dev"
subnetwork_name = "dev"

# Staging overrides: smaller footprint, cheaper, easier teardown
client_target_size     = 1
client_max_size        = 2
server_target_size     = 1
db_availability_type   = "ZONAL"
db_deletion_protection = false
