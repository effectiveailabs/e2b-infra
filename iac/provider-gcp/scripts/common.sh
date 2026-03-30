#!/usr/bin/env bash
# Shared helpers for Terraform wrapper scripts.

STATE_BUCKET="${TF_STATE_BUCKET:-effectiveai-e2b-terraform-state}"

# Extract -backend-config flags from arguments so they can be forwarded
# to terraform init separately from var-file / other plan/apply flags.
_extract_backend_config() {
  BACKEND_ARGS=()
  REMAINING_ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -backend-config=*)
        BACKEND_ARGS+=("$1"); shift ;;
      -backend-config)
        BACKEND_ARGS+=("$1" "$2"); shift 2 ;;
      *)
        REMAINING_ARGS+=("$1"); shift ;;
    esac
  done
}

# ensure_backend bootstraps the GCS state bucket if it doesn't exist yet,
# then runs terraform init with the appropriate backend config.
# Pass the caller's "$@" so -backend-config and -var-file are forwarded.
ensure_backend() {
  _extract_backend_config "$@"

  if ! gcloud storage buckets describe "gs://${STATE_BUCKET}" >/dev/null 2>&1; then
    echo "State bucket ${STATE_BUCKET} not found. Bootstrapping it with local state..."
    terraform init -backend=false -reconfigure
    terraform apply -target=google_storage_bucket.terraform_state -auto-approve "${REMAINING_ARGS[@]}"
    terraform init -migrate-state -force-copy "${BACKEND_ARGS[@]}"
  else
    terraform init -reconfigure "${BACKEND_ARGS[@]}"
  fi
}

