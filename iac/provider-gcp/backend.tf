terraform {
  backend "gcs" {
    # Configured via -backend-config at init time:
    #   terraform init -backend-config=environments/staging.tfbackend
    # See environments/*.tfbackend for per-env bucket + prefix.
  }
}
