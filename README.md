# Vaultwarden with Tailscale Deployment

A secure, self-hosted password manager using Vaultwarden and Tailscale.

## Prerequisites

- Docker and Docker Compose installed
- Tailscale account and Auth Key
- Domain name configured in Tailscale

## Setup Instructions

1. **Configure Environment Variables**
   - Copy `.env.example` to `.env` if provided, or update the existing `.env` file
   - Replace the following values in `.env`:
     - `TS_AUTHKEY`: Your Tailscale auth key
     - `TS_CERT_DOMAIN`: Your Tailscale machine name (e.g., `vaultwarden.your-tailnet.ts.net`)
     - `DOMAIN`: Full HTTPS URL (e.g., `https://vaultwarden.your-tailnet.ts.net`)
     - `ADMIN_TOKEN`: Generate a new secure admin token

2. **Generate Admin Token**
   ```bash
   # Generate a new admin token
   docker run --rm -it vaultwarden/server:latest /vaultwarden hash --preset argon2id
   ```

3. **Start Services**
   ```bash
   docker compose up -d
   ```

4. **Verify Deployment**
   - Check container status: `docker compose ps`
   - View logs: `docker compose logs -f`
   - Access via your Tailscale domain

5. **Initial Configuration**
   - Access the admin panel at `https://your-domain/admin`
   - Use your admin token to login
   - Configure additional security settings

## Security Recommendations

- Set `SIGNUPS_ALLOWED=false` after creating your accounts
- Regularly backup using the provided `backup.sh` script
- Keep Docker images updated
- Monitor logs for suspicious activity
- Use strong, unique admin token

## Backup & Disaster Recovery

### Critical Components to Backup

Your Vaultwarden deployment has several critical components that **must** be backed up for complete disaster recovery:

| Component | Path | Critical? | Purpose |
|-----------|------|-----------|---------|
| **Vaultwarden Database** | `vw-data/` | ✅ **CRITICAL** | User accounts, passwords, vault data |
| **Tailscale State** | `tailscale-state/` | ✅ **CRITICAL** | Machine identity, prevents new machine on restore |
| **Environment Config** | `.env` | ✅ **CRITICAL** | Auth keys, domain, admin token |
| **Docker Config** | `docker-compose.yml` | ✅ **CRITICAL** | Service configuration |
| **Tailscale Serve Config** | `tailscale-config/` | ⚠️ **IMPORTANT** | Proxy configuration |
| **Application Logs** | `vw-logs/` | ℹ️ Optional | Troubleshooting history |

### Automated Backup

Use the provided comprehensive backup script:

```bash
# Run backup (stops containers briefly for consistency)
./backup.sh

# For complete backup including Tailscale machine identity (requires sudo)
sudo ./backup.sh
```

**What the backup includes:**
- 🔐 Complete Vaultwarden database and user data (**Always included**)
- ⚙️ All configuration files (`.env`, `docker-compose.yml`) (**Always included**)
- 🌐 Tailscale serve configuration (**Always included**)
- 📝 Application logs (**Always included**)
- 🔑 Tailscale machine identity (*Requires sudo - prevents creating new machines*)
- 🧹 Automatic cleanup (keeps last 7 backups)

**⚠️ Important**: Regular backup works without sudo but **excludes Tailscale machine state**. Without Tailscale state, restoration will create a new machine (e.g., `ser-2` instead of `ser-1`). For **complete disaster recovery**, run `sudo ./backup.sh` to include machine identity.

### Manual Backup (Alternative)

If you prefer manual backups:

```bash
# Stop services
docker compose down

# Create backup directory
mkdir -p backups/manual_$(date +%Y%m%d)

# Copy critical components
cp -r vw-data/ backups/manual_$(date +%Y%m%d)/
cp -r tailscale-state/ backups/manual_$(date +%Y%m%d)/
cp -r tailscale-config/ backups/manual_$(date +%Y%m%d)/
cp .env docker-compose.yml backups/manual_$(date +%Y%m%d)/

# Restart services
docker compose up -d
```

### Server Migration / Disaster Recovery

To migrate to a new server or recover from failure:

#### 1. **Prepare New Server**
```bash
# Install Docker & Docker Compose on new server
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo apt install docker-compose-plugin
```

#### 2. **Transfer Backup**
```bash
# Copy backup file to new server
scp backups/vaultwarden_complete_backup_YYYYMMDD_HHMMSS.tar.gz user@newserver:/home/user/
```

#### 3. **Restore Everything**
```bash
# On new server, extract backup
mkdir vaultwarden && cd vaultwarden
tar -xzf vaultwarden_complete_backup_YYYYMMDD_HHMMSS.tar.gz

# Start services (Tailscale will use same machine identity!)
docker compose up -d
```

#### 4. **Verify Recovery**
```bash
# Check services are running
docker compose ps  

# Verify Tailscale serves on same hostname  
docker compose exec tailscale tailscale serve status

# Test access via browser
# Should be accessible at same URL: https://ser-1.taile9f91c.ts.net
```

### ⚠️ **Critical Recovery Notes**

- **Tailscale Identity**: The `tailscale-state/` directory preserves your machine identity. Without it, you'll get a new machine name (e.g., `ser-2` instead of `ser-1`)
- **Admin Access**: Your admin token is preserved in the `.env` file
- **User Data**: All passwords and vault data are in `vw-data/db.sqlite3`
- **Domain Configuration**: Ensure the new server can reach the same Tailscale network

### Backup Schedule Recommendations

- **Daily**: Automated backup via cron
  ```bash
  # Add to crontab: daily at 2 AM
  0 2 * * * cd /path/to/vaultwarden && ./backup.sh
  ```
- **Before Updates**: Always backup before updating Docker images
  ```bash
  ./backup.sh && docker compose pull && docker compose up -d
  ```
- **Before Migration**: Create fresh backup before any server changes

### Testing Your Backups

**Regularly test that your backups work:**

1. Stop current deployment: `docker compose down`
2. Rename current directory: `mv vaultwarden vaultwarden.old`
3. Restore from backup following recovery steps above
4. Verify everything works, then clean up: `rm -rf vaultwarden.old`

## Troubleshooting

- **Container won't start**: Check logs with `docker compose logs tailscale`
- **Can't access via Tailscale**: Verify TS_CERT_DOMAIN matches your Tailscale machine name
- **Health check failing**: Ensure ROCKET_PORT matches the port in serve.json

## Directory Structure

```
├── docker-compose.yml      # Main container configuration
├── .env                    # Environment variables (sensitive)
├── tailscale-config/
│   └── serve.json         # Tailscale proxy configuration
├── tailscale-state/       # Tailscale machine identity (CRITICAL for persistence)
├── vw-data/               # Vaultwarden database & user data (CRITICAL)
│   ├── db.sqlite3         # Main database file
│   ├── db.sqlite3-shm     # Database shared memory
│   └── db.sqlite3-wal     # Database write-ahead log
├── vw-logs/               # Application logs
├── backups/               # Automated backup storage
│   └── vaultwarden_complete_backup_*.tar.gz
└── backup.sh              # Comprehensive backup script
```

**🔴 Critical Files**: Never lose `vw-data/`, `tailscale-state/`, or `.env`  
**⚠️ Important Files**: `docker-compose.yml`, `tailscale-config/`  
**ℹ️ Optional Files**: `vw-logs/`, `backups/`