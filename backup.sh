#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${1:-$SCRIPT_DIR/backups}"

BACKUP_SCRIPT_PATH="${BACKUP_SCRIPT:-}"
if [ -z "$BACKUP_SCRIPT_PATH" ]; then
  for candidate in \
    "$SCRIPT_DIR/../backup_utils/server_backups/vw_backup.sh" \
    "$SCRIPT_DIR/../backup-utils/server_backups/vw_backup.sh"
  do
    if [ -x "$candidate" ]; then
      BACKUP_SCRIPT_PATH="$candidate"
      break
    fi
  done
fi

if [ -z "$BACKUP_SCRIPT_PATH" ] || [ ! -f "$BACKUP_SCRIPT_PATH" ]; then
  echo "Backup script not found or not executable. Checked common locations under $SCRIPT_DIR/../" >&2
  echo "Set BACKUP_SCRIPT=/path/to/vw_backup.sh or restore the backup utilities directory." >&2
  exit 1
fi

if [ ! -x "$BACKUP_SCRIPT_PATH" ]; then
  chmod +x "$BACKUP_SCRIPT_PATH"
fi

exec "$BACKUP_SCRIPT_PATH" "$SCRIPT_DIR" "$BACKUP_DIR"
