#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ensure_backend "$@"
# REMAINING_ARGS is set by ensure_backend (strips -backend-config flags).
terraform plan -lock-timeout=5m -out=tfplan "${REMAINING_ARGS[@]}"

