#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${1:-$SCRIPT_DIR/backups}"
DATE="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="vaultwarden_backup_$DATE.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

cd "$SCRIPT_DIR"
mkdir -p "$BACKUP_DIR"

restart_stack=false
if docker compose ps --status running --services | grep -qx vaultwarden; then
  restart_stack=true
  docker compose stop vaultwarden
fi

cleanup() {
  if [ "$restart_stack" = true ]; then
    docker compose up -d vaultwarden >/dev/null
  fi
}
trap cleanup EXIT

items=()
for item in vw-data .env docker-compose.yml .env.sample backup.sh redeploy.sh install-systemd-service.sh README.md vw-logs; do
  [ -e "$item" ] && items+=("$item")
done

if [ "${#items[@]}" -eq 0 ]; then
  echo "Nothing to back up" >&2
  exit 1
fi

tar -czf "$BACKUP_PATH" "${items[@]}"

echo "Backup created: $BACKUP_PATH"
echo "Host Tailscale state is not included; it lives outside this project."
