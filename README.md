# Vaultwarden with Tailscale Deployment

A secure, self-hosted password manager using Vaultwarden and Tailscale.

## Prerequisites

- Docker and Docker Compose installed
- Tailscale account and Auth Key
- Domain name configured in Tailscale

## Setup Instructions

### 1. **Configure Environment Variables**
   
   Update the `.env` file with your specific values:
   ```bash
   # Vaultwarden Configuration
   ADMIN_TOKEN=$2a$12$... # Leave commented out to disable admin panel
   DOMAIN=https://ser-1.taile9f91c.ts.net
   ROCKET_PORT=80

   # Tailscale Configuration  
   TS_AUTHKEY=tskey-auth-YOUR_KEY_HERE
   TS_CERT_DOMAIN=ser-1.taile9f91c.ts.net
   TS_HOSTNAME=ser-1

   # Security Settings
   SIGNUPS_ALLOWED=true  # Set to false after creating accounts
   WEBSOCKET_ENABLED=true
   SHOW_PASSWORD_HINT=false
   ```

### 2. **Generate Tailscale Auth Key**
   - Go to [Tailscale Auth Keys](https://login.tailscale.com/admin/settings/keys)
   - Click "Generate auth key"
   - **Important settings:**
     - ✅ **Reusable**: Enable (allows container restarts)
     - ✅ **Preauthorized**: Enable 
     - ✅ **Expiry**: Set to 90+ days
   - Copy the key and update `TS_AUTHKEY` in `.env`

### 3. **Generate Admin Token** (Optional)
   ```bash
   # Generate a secure admin token
   docker run --rm -it vaultwarden/server:latest /vaultwarden hash --preset argon2id
   ```
   
   To disable admin panel: Comment out `ADMIN_TOKEN` line in `.env`

### 4. **Clean Old Tailscale Nodes**
   - Visit [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
   - Delete any old/offline nodes with the same hostname (`ser-1-1`, `ser-1-2`, etc.)
   - This prevents hostname conflicts

### 5. **Start Services**
   ```bash
   # Stop any existing containers
   docker compose down
   
   # Clear Tailscale state for fresh start
   sudo rm -rf ./tailscale-state/*
   
   # Start services
   docker compose up -d
   ```

### 6. **Verify Deployment**
   ```bash
   # Check container status (both should be healthy)
   docker compose ps
   
   # Verify Tailscale hostname
   docker compose exec tailscale tailscale status
   
   # Check service accessibility
   curl -I https://ser-1.taile9f91c.ts.net/
   
   # View logs if needed
   docker compose logs -f
   ```

### 7. **Enable Tailscale Funnel (Public Internet Access)**

   **Important**: By default, your Vaultwarden is only accessible within your Tailscale network (tailnet). To make it accessible from the public internet, you need to enable **Tailscale Funnel**.

   **Difference between Serve and Funnel:**
   - **Tailscale Serve**: Only accessible to devices in your Tailscale network
   - **Tailscale Funnel**: Accessible from anywhere on the public internet

   #### Enable Funnel in Tailscale Admin Console:
   1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/dns)
   2. Navigate to the **DNS** tab
   3. Find **Funnel** settings and **enable it** for your tailnet
   4. Tag your machine for public access:
      - Go to [Machines](https://login.tailscale.com/admin/machines)
      - Find your `ser-1` machine
      - Add tag: `tag:public`
   
   #### Enable Funnel via Command Line:
   ```bash
   # Enable Funnel to expose port 80 via HTTPS on port 443
   docker exec tailscale tailscale funnel --bg --https 443 80
   ```
   
   #### Verify Funnel Status:
   ```bash
   # Check if Funnel is enabled (should show "Funnel on")
   docker exec tailscale tailscale funnel status
   
   # Test public accessibility
   curl -I https://ser-1.taile9f91c.ts.net/
   ```

   #### Update serve.json for Funnel:
   Your [serve.json](tailscale-config/serve.json) should include `"Funnel": true`:
   ```json
   {
     "TCP": {
       "443": {
         "HTTPS": true,
         "Funnel": true
       }
     },
     "Web": {
       "ser-1.taile9f91c.ts.net:443": {
         "Handlers": {
           "/": {
             "Proxy": "http://127.0.0.1:80"
           }
         }
       }
     }
   }
   ```

### 8. **Initial Setup**
   - Access Vaultwarden at: `https://ser-1.taile9f91c.ts.net`
   - Create your first user account
   - Set `SIGNUPS_ALLOWED=false` in `.env` and restart after setup
   - Access admin panel (if enabled) at `/admin`

## Troubleshooting

### DNS Resolution Issues (After Enabling Funnel)

If you get "DNS address could not be found" errors after enabling Funnel, this is typically due to **DNS caching**:

#### **Clear DNS Cache:**
```bash
# Windows
ipconfig /flushdns

# macOS  
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Linux
sudo systemctl restart systemd-resolved
# or
sudo resolvectl flush-caches
```

#### **Browser Solutions:**
- Clear browser cache: `Ctrl+Shift+Delete` → Clear all data
- Hard refresh: `Ctrl+Shift+R` (or `Cmd+Shift+R` on macOS)
- Try incognito/private mode (bypasses browser DNS cache)
- Try a different browser

#### **Verify Funnel Status:**
```bash
# Should show "Funnel on" not "tailnet only"
docker exec tailscale tailscale funnel status

# Test DNS resolution
nslookup ser-1.taile9f91c.ts.net 8.8.8.8

# Test public accessibility  
curl -I https://ser-1.taile9f91c.ts.net/
```

### Mobile App HTTP 404 Errors

If your mobile app shows login errors or HTTP 404:

#### **1. Clear App Data:**
- Settings → About → Clear Data (or uninstall/reinstall)
- Add new account with correct server URL

#### **2. Verify Server Configuration:**
Ensure these URLs are correct in mobile app:
- **Server URL**: `https://ser-1.taile9f91c.ts.net`
- **API Server URL**: `https://ser-1.taile9f91c.ts.net/api`
- **Identity Server URL**: `https://ser-1.taile9f91c.ts.net/identity`
- **Web Vault URL**: `https://ser-1.taile9f91c.ts.net`

#### **3. Test API Endpoints:**
```bash
# Test config endpoint
curl https://ser-1.taile9f91c.ts.net/api/config

# Test prelogin endpoint (requires POST with email)
curl -X POST -H "Content-Type: application/json" \
     -d '{"email":"test@example.com"}' \
     https://ser-1.taile9f91c.ts.net/api/accounts/prelogin
```

### Funnel Not Working

#### **Enable Funnel Permissions:**
1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/dns) → DNS tab
2. Enable **Funnel** for your tailnet
3. Tag machine with `tag:public` in [Machines](https://login.tailscale.com/admin/machines)

#### **Manual Funnel Activation:**
```bash
# If serve.json config isn't working, enable manually
docker exec tailscale tailscale funnel --bg --https 443 80

# Verify it's enabled
docker exec tailscale tailscale funnel status
# Should show: "# Funnel on: - https://ser-1.taile9f91c.ts.net"
```

### Hostname Issues (`ser-1-2`, `ser-1-3` appearing)
```bash
# Stop containers
docker compose down

# Clean Tailscale state
sudo rm -rf ./tailscale-state/*

# Delete old nodes from Tailscale admin console
# Then restart
docker compose up -d
```

### Auth Key Expired
1. Generate new auth key in Tailscale admin console
2. Update `TS_AUTHKEY` in `.env`
3. Restart: `docker compose restart tailscale`

### Admin Panel Issues
- **To disable admin panel**: Comment out `ADMIN_TOKEN` in `.env`
- **To apply changes**: Remove `./vw-data/config.json` and restart
- **To re-enable**: Uncomment `ADMIN_TOKEN` and restart

### Fresh Start (Reset All Data)
```bash
# Stop containers
docker compose down

# Clear all Vaultwarden data (WARNING: Deletes all users/passwords!)
sudo rm -rf ./vw-data/*
rm -rf ./vw-logs/*

# Start fresh
docker compose up -d
```

## Configuration Details

### docker-compose.yml Key Settings
- Vaultwarden uses Tailscale's network stack (`network_mode: service:tailscale`)
- Tailscale serves HTTPS on port 443, proxies to Vaultwarden on port 80
- `TS_EXTRA_ARGS=--accept-dns=false --accept-routes` prevents conflicts

### serve.json Configuration

**For Tailscale Serve (tailnet-only):**
```json
{
  "TCP": { "443": { "HTTPS": true } },
  "Web": {
    "ser-1.taile9f91c.ts.net:443": {
      "Handlers": { "/": { "Proxy": "http://127.0.0.1:80" } }
    }
  }
}
```

**For Tailscale Funnel (public internet):**
```json
{
  "TCP": { 
    "443": { 
      "HTTPS": true,
      "Funnel": true 
    } 
  },
  "Web": {
    "ser-1.taile9f91c.ts.net:443": {
      "Handlers": { "/": { "Proxy": "http://127.0.0.1:80" } }
    }
  }
}
```

**Note**: The domain must be hardcoded (not `${TS_CERT_DOMAIN}`) for Funnel to work properly.

## Security Recommendations

### **Critical for Public Internet Access (Funnel):**
- **IMMEDIATELY set `SIGNUPS_ALLOWED=false`** after creating your accounts
- **Enable strong rate limiting** in Vaultwarden (built-in protection)
- **Monitor admin panel logs** regularly for suspicious activity
- **Use fail2ban** or similar to block repeated login attempts
- **Keep Docker images updated**: `docker compose pull && docker compose up -d`

### **General Security:**
- Set `SIGNUPS_ALLOWED=false` after creating accounts
- Use strong, unique master passwords  
- Enable 2FA for all accounts
- Regularly backup using the provided `backup.sh` script
- Monitor logs for suspicious activity: `docker compose logs -f`
- Disable admin panel for production use (comment out `ADMIN_TOKEN`)

### **Network Security (Funnel vs Serve):**
- **Tailscale Serve**: Only accessible to your Tailscale devices (more secure)
- **Tailscale Funnel**: Public internet access (convenient but requires stronger security)
- Consider using **Serve** for personal use and **Funnel** only when needed

## Backup & Recovery

### Manual Backup
```bash
# Run the backup script
./backup.sh

# Backup files are stored in ./backups/ with timestamps
```

### Restore from Backup
```bash
# Stop services
docker compose down

# Restore data from backup
cp -r ./backups/vw-data.TIMESTAMP/* ./vw-data/
cp -r ./backups/tailscale-state.TIMESTAMP/* ./tailscale-state/

# Start services  
docker compose up -d
```

## Maintenance

### Update Containers
```bash
docker compose pull
docker compose up -d
```

### View Resource Usage
```bash
docker compose exec vaultwarden df -h /data
docker stats --no-stream
```

### Container Health Checks
```bash
# All containers should show "healthy"
docker compose ps

# Check individual service logs
docker compose logs tailscale
docker compose logs vaultwarden
```

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

## Database Reset (Fresh Start)

If you need to completely reset your Vaultwarden instance (remove all users, organizations, and vault data), follow these steps:

### ⚠️ **Warning**
This will permanently delete ALL user data, passwords, and organizations. Create a backup first if you want to preserve any data.

### **When to Use Database Reset:**
- "Registration not allowed or user already exists" errors when trying to create accounts
- Forgotten admin credentials and need to start over
- Testing/development scenarios requiring clean state
- Corrupted database requiring fresh installation

### **Reset Procedure:**

1. **Create Backup** (Optional but recommended):
   ```bash
   # Create timestamped backup
   ./backup.sh
   # Or manual backup
   sudo cp -r vw-data vw-data-backup-$(date +%Y%m%d_%H%M%S)
   ```

2. **Stop Services:**
   ```bash
   docker compose down
   ```

3. **Reset Database:**
   ```bash
   # Remove database files (requires sudo due to container permissions)
   sudo rm -rf vw-data/db.sqlite3*
   
   # Preserve other important files (icons, keys, etc.)
   # Only database files are removed, configuration is preserved
   ```

4. **Restart Services:**
   ```bash
   docker compose up -d
   ```

5. **Verify Clean State:**
   ```bash
   # Check container health
   docker compose ps
   
   # Visit web vault - should show clean login/registration page
   # https://your-tailscale-domain
   ```

### **After Database Reset:**

1. **Enable Signups Temporarily** (if needed):
   - Set `SIGNUPS_ALLOWED=true` in `.env`
   - Restart: `docker compose restart vaultwarden`

2. **Create New Admin Account:**
   - Go to your Tailscale domain (web vault, not admin panel)
   - Create your admin user account
   - Create your organization through web vault

3. **Secure System:**
   - Set `SIGNUPS_ALLOWED=false` in `.env` 
   - Restart: `docker compose restart vaultwarden`
   - Verify admin panel access with your admin token

### **Important Notes:**
- **Tailscale state preserved**: Your machine identity and domain remain unchanged
- **Configuration preserved**: `.env`, `docker-compose.yml`, and `tailscale-config/` are untouched
- **Only user data reset**: Database, organizations, and vault entries are removed
- **Admin token unchanged**: Your admin panel access remains the same

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