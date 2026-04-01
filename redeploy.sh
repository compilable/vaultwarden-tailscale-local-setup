#!/usr/bin/env bash
set -euo pipefail

# Redeploy the stack by removing current containers and compose-managed images,
# then starting fresh containers from docker-compose.yml.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[1/4] Stopping and removing compose containers..."
docker compose down --remove-orphans

echo "[2/4] Collecting compose image names..."
mapfile -t image_names < <(docker compose config --images | sort -u)

echo "[3/4] Removing compose images (if any)..."
if ((${#image_names[@]} > 0)); then
  for image in "${image_names[@]}"; do
    docker image rm -f "$image" || true
  done
else
  echo "No compose images found to remove."
fi

echo "[4/4] Starting compose services..."
docker compose up -d

echo "Done. Current status:"
docker compose ps
