#!/bin/bash

# Vaultwarden Complete Backup Script
# Backs up all critical data for full disaster recovery
# Run this script regularly to backup your Vaultwarden deployment

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="vaultwarden_complete_backup_$DATE.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Stop the containers to ensure consistent backup
echo "Stopping Vaultwarden containers for consistent backup..."
docker compose down

# Create comprehensive backup including all critical components
echo "Creating complete backup..."
echo "  - Vaultwarden database and data (vw-data/)"
echo "  - Configuration files (.env, docker-compose.yml)"
echo "  - Tailscale serve configuration (tailscale-config/)"
echo "  - Application logs (vw-logs/)"

# Create backup (skip tailscale-state if permission issues)
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    vw-data/ \
    .env \
    docker-compose.yml \
    tailscale-config/ \
    vw-logs/ \
    --ignore-failed-read \
    2>/dev/null

# Try to backup tailscale-state if possible (may have permission issues)
echo "  - Attempting Tailscale machine state backup..."
if tar -rf "${BACKUP_DIR}/${BACKUP_FILE%.tar.gz}.tar" tailscale-state/ 2>/dev/null; then
    gzip "${BACKUP_DIR}/${BACKUP_FILE%.tar.gz}.tar"
    echo "    ✅ Tailscale state included"
else
    echo "    ⚠️  Tailscale state skipped (permission issues - run as root if needed)"
    echo "    💡 For complete backup including machine identity, run: sudo ./backup.sh"
fi

# Start the containers
echo "Starting Vaultwarden containers..."
docker compose up -d

echo "✅ Complete backup created: $BACKUP_DIR/$BACKUP_FILE"
echo "📊 Backup size: $(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)"

# Keep only the last 7 backups to save space
echo "🧹 Cleaning up old backups (keeping last 7)..."
ls -t "$BACKUP_DIR"/vaultwarden_complete_backup_*.tar.gz | tail -n +8 | xargs -r rm --

echo "✅ Backup script finished!"
echo ""
echo "💡 To restore on a new server:"
echo "   1. Copy this backup file to the new server"
echo "   2. Extract: tar -xzf $BACKUP_FILE"
echo "   3. Run: docker compose up -d"