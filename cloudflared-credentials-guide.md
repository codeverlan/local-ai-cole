# Cloudflared Credentials Guide

This document explains the credentials needed to run Cloudflared on your host system for integration with Traefik.

## Required Credentials

### 1. Cloudflare Account Credentials

You need a Cloudflare account to authenticate Cloudflared. During the initial setup, you'll run:

```bash
cloudflared tunnel login
```

This will open a browser window where you'll log in with your Cloudflare account credentials. After successful authentication, a certificate file will be generated at:

```
~/.cloudflared/cert.pem
```

This certificate is used for API authentication with Cloudflare and is required to create and manage tunnels.

### 2. Tunnel Credentials File

When you create a tunnel with:

```bash
cloudflared tunnel create <tunnel-name>
```

Cloudflared generates a JSON credentials file at:

```
~/.cloudflared/<tunnel-id>.json
```

This file contains the credentials needed for the tunnel to authenticate with Cloudflare's edge. It includes:

- A secret used to authenticate the tunnel
- The tunnel ID
- Account ID information

Example content (values will be different):

```json
{
  "AccountTag": "0123456789abcdef0123456789abcdef",
  "TunnelID": "abcdef01-2345-6789-abcd-ef0123456789",
  "TunnelName": "local-ai-cole",
  "TunnelSecret": "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz01=="
}
```

This file must be kept secure as it contains sensitive information that could allow others to impersonate your tunnel.

### 3. Configuration File

The configuration file (`/etc/cloudflared/config.yml`) references the credentials file:

```yaml
tunnel: abcdef01-2345-6789-abcd-ef0123456789
credentials-file: /root/.cloudflared/abcdef01-2345-6789-abcd-ef0123456789.json

ingress:
  - hostname: "*.yourdomain.com"
    service: http://localhost:80
  - service: http_status:404
```

## Credential File Locations

When running Cloudflared as a system service:

1. **Certificate file**: `/root/.cloudflared/cert.pem`
2. **Tunnel credentials file**: `/root/.cloudflared/<tunnel-id>.json`
3. **Configuration file**: `/etc/cloudflared/config.yml`

## Security Considerations

1. **Permissions**: Ensure the credentials file has restricted permissions:
   ```bash
   sudo chmod 600 /root/.cloudflared/<tunnel-id>.json
   ```

2. **Backup**: Keep a secure backup of your credentials file. If you lose it, you won't be able to reconnect to your tunnel and will need to create a new one.

3. **Do not share**: Never share your credentials file or include it in version control systems.

## Credential Management

The provided `setup-host-cloudflared.sh` script handles credential management automatically:

1. It runs `cloudflared tunnel login` to authenticate with Cloudflare
2. Creates a tunnel and saves the credentials file
3. Copies the credentials file to the system location
4. Sets the correct permissions
5. Creates the configuration file referencing the credentials

## Manual Credential Setup

If you prefer to set up credentials manually:

1. Run `cloudflared tunnel login` as your user
2. Create a tunnel: `cloudflared tunnel create local-ai-cole`
3. Copy the credentials file to the system location:
   ```bash
   sudo mkdir -p /root/.cloudflared
   sudo cp ~/.cloudflared/<tunnel-id>.json /root/.cloudflared/
   sudo chmod 600 /root/.cloudflared/<tunnel-id>.json
   ```
4. Create the configuration file:
   ```bash
   sudo mkdir -p /etc/cloudflared
   sudo nano /etc/cloudflared/config.yml
   ```
   Add the configuration referencing the credentials file.

## Troubleshooting Credential Issues

If you encounter credential-related issues:

1. **Authentication failures**: Re-run `cloudflared tunnel login`
2. **Tunnel connection errors**: Verify the credentials file exists and has the correct permissions
3. **"Unauthorized" errors**: Ensure the tunnel ID in the config matches the credentials file