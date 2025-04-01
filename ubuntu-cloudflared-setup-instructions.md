# Setting Up Cloudflared on Ubuntu 22.04

These instructions will guide you through setting up cloudflared as a system service on Ubuntu 22.04, working with Traefik on port 80.

## Prerequisites

- Ubuntu 22.04
- Root/sudo access
- A Cloudflare account
- A domain managed by Cloudflare
- Traefik running on port 80

## Step 1: Install Cloudflared

```bash
# Add Cloudflare GPG key
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add Cloudflare repository
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list

# Update and install
sudo apt update
sudo apt install -y cloudflared
```

## Step 2: Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This will open a browser window where you'll need to log in to your Cloudflare account and authorize the Cloudflared application. After authorization, a certificate file will be downloaded to `~/.cloudflared/cert.pem`.

## Step 3: Create a Tunnel

```bash
cloudflared tunnel create local-ai-cole
```

This command will:
1. Create a new tunnel named "local-ai-cole"
2. Generate a credentials file in `~/.cloudflared/`
3. Output the Tunnel ID (save this for later)

Example output:
```
Created tunnel local-ai-cole with id 6ff42ae2-765d-4adf-8112-31c55c1551ef
```

## Step 4: Configure the Tunnel

Create a configuration file:

```bash
sudo mkdir -p /etc/cloudflared
sudo nano /etc/cloudflared/config.yml
```

Add the following content (replace with your values):

```yaml
# Tunnel ID from the previous step
tunnel: 6ff42ae2-765d-4adf-8112-31c55c1551ef
credentials-file: /root/.cloudflared/6ff42ae2-765d-4adf-8112-31c55c1551ef.json

# Ingress rules define how traffic is routed to your services
ingress:
  # Route traffic to Traefik
  - hostname: "*.yourdomain.com"
    service: http://localhost:80
  
  # Default catch-all rule
  - service: http_status:404
```

## Step 5: Copy Credentials File to System Location

```bash
# Create directory if it doesn't exist
sudo mkdir -p /root/.cloudflared

# Copy credentials file (replace with your tunnel ID)
sudo cp ~/.cloudflared/6ff42ae2-765d-4adf-8112-31c55c1551ef.json /root/.cloudflared/

# Set proper permissions
sudo chmod 600 /root/.cloudflared/6ff42ae2-765d-4adf-8112-31c55c1551ef.json
```

## Step 6: Configure DNS Records

For each subdomain you want to route through the tunnel:

```bash
cloudflared tunnel route dns 6ff42ae2-765d-4adf-8112-31c55c1551ef n8n.yourdomain.com
cloudflared tunnel route dns 6ff42ae2-765d-4adf-8112-31c55c1551ef webui.yourdomain.com
cloudflared tunnel route dns 6ff42ae2-765d-4adf-8112-31c55c1551ef flowise.yourdomain.com
cloudflared tunnel route dns 6ff42ae2-765d-4adf-8112-31c55c1551ef ollama.yourdomain.com
cloudflared tunnel route dns 6ff42ae2-765d-4adf-8112-31c55c1551ef supabase.yourdomain.com
cloudflared tunnel route dns 6ff42ae2-765d-4adf-8112-31c55c1551ef searxng.yourdomain.com
```

## Step 7: Install as a System Service

```bash
sudo cloudflared service install
```

## Step 8: Start and Enable the Service

```bash
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

## Step 9: Verify the Service is Running

```bash
sudo systemctl status cloudflared
```

## Step 10: Check Tunnel Connection

```bash
cloudflared tunnel info 6ff42ae2-765d-4adf-8112-31c55c1551ef
```

## Troubleshooting

If you encounter issues:

1. Check the service logs:
   ```bash
   sudo journalctl -u cloudflared
   ```

2. Verify the configuration:
   ```bash
   cloudflared tunnel ingress validate
   ```

3. Check if the tunnel is connected:
   ```bash
   cloudflared tunnel list
   ```

## Required Credentials Summary

1. **Cloudflare Account Credentials**: Used during `cloudflared tunnel login`
2. **Tunnel Credentials File**: JSON file created at `~/.cloudflared/<tunnel-id>.json`
3. **Tunnel ID**: Used in configuration and DNS setup
4. **Domain Name**: Your Cloudflare-managed domain

The most important credential is the tunnel credentials JSON file, which must be:
- Kept secure (permissions set to 600)
- Copied to the system location for the service
- Referenced correctly in the config.yml file