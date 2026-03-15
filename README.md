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

## Backup

Run the backup script:
```bash
./backup.sh
```

This will:
- Stop containers safely
- Create compressed backup of data
- Restart containers  
- Keep last 7 backups automatically

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
├── vw-data/               # Vaultwarden data (persistent)
├── vw-logs/               # Application logs
├── backups/               # Automated backups
└── backup.sh              # Backup script
```