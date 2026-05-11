#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if present
if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a
  source "$ROOT_DIR/.env"
  set +a
fi

: "${DB_USER:?DB_USER not set}"
: "${DB_PASSWORD:?DB_PASSWORD not set}"
: "${DB_HOST:?DB_HOST not set}"
: "${DB_PORT:?DB_PORT not set}"
: "${DB_NAME:?DB_NAME not set}"

DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable"
MIGRATIONS_DIR="$ROOT_DIR/sql/migrations"

CMD="${1:-}"

case "$CMD" in
  up)
    migrate -path "$MIGRATIONS_DIR" -database "$DB_URL" up
    ;;
  down)
    STEPS="${2:-1}"
    migrate -path "$MIGRATIONS_DIR" -database "$DB_URL" down "$STEPS"
    ;;
  force)
    VERSION="${2:?Usage: migrate-force VERSION=<number>}"
    migrate -path "$MIGRATIONS_DIR" -database "$DB_URL" force "$VERSION"
    ;;
  *)
    echo "Usage: $0 {up|down [steps]|force <version>}" >&2
    exit 1
    ;;
esac
