#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="${BACKUP_SCRIPT:-$SCRIPT_DIR/../backup-utils/server_backups/vw_backup.sh}"
BACKUP_DIR="${1:-$SCRIPT_DIR/backups}"

if [ ! -x "$BACKUP_SCRIPT" ]; then
  echo "Backup script not found or not executable: $BACKUP_SCRIPT" >&2
  echo "Set BACKUP_SCRIPT=/path/to/vw_backup.sh or restore ../backup-utils." >&2
  exit 1
fi

exec "$BACKUP_SCRIPT" "$SCRIPT_DIR" "$BACKUP_DIR"
