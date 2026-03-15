#!/bin/bash

# Vaultwarden Backup Script
# Run this script regularly to backup your Vaultwarden data

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="vaultwarden_backup_$DATE.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Stop the containers
echo "Stopping Vaultwarden containers..."
docker compose down

# Create backup
echo "Creating backup..."
tar -czf "$BACKUP_DIR/$BACKUP_FILE" vw-data/

# Start the containers
echo "Starting Vaultwarden containers..."
docker compose up -d

echo "Backup completed: $BACKUP_DIR/$BACKUP_FILE"

# Keep only the last 7 backups
echo "Cleaning up old backups..."
ls -t "$BACKUP_DIR"/vaultwarden_backup_*.tar.gz | tail -n +8 | xargs -r rm --

echo "Backup script finished!"