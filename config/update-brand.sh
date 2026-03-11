#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COMPOSE_ARGS=(-f deploy-compose.yml -f docker-compose.override.yml)

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker command not found."
  exit 1
fi

echo "[1/4] Building local API image with updated frontend assets..."
docker compose "${COMPOSE_ARGS[@]}" build api

echo "[2/4] Recreating api and client containers..."
docker compose "${COMPOSE_ARGS[@]}" up -d --force-recreate api client

echo "[3/4] Verifying deployed branding assets in dist..."
docker exec LibreChat-API sh -lc 'find /app/client/dist/assets -maxdepth 1 -type f | grep -E "logo|favicon|apple-touch-icon" | sort' || true

echo "[4/4] Checking HTTP status for logo and favicons..."
for file in logo.svg favicon-16x16.png favicon-32x32.png favicon.ico apple-touch-icon-180x180.png; do
  echo "--- $file"
  curl -sSI "http://localhost/assets/$file" | sed -n '1,8p'
done

echo "Done. If browser still shows old icons, hard refresh with Cmd+Shift+R."
