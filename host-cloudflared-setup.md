# Setting Up Cloudflared on the Host System

This guide explains how to install and configure Cloudflared directly on your host system (rather than in a Docker container) to work with Traefik for SSL termination.

## Required Credentials

To set up Cloudflared on your host system, you'll need:

1. **Cloudflare Account**: You need a Cloudflare account (free tier is sufficient)
2. **Domain on Cloudflare**: A domain managed by Cloudflare's nameservers
3. **Cloudflare API Token**: For authentication (optional, only if using the API)
4. **Tunnel Credentials File**: A JSON file containing your tunnel credentials

## Installation Steps

### 1. Install Cloudflared

#### On Debian/Ubuntu:
```bash
# Add Cloudflare GPG key
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add Cloudflare repository
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list

# Update and install
sudo apt update
sudo apt install cloudflared
```

#### On RHEL/CentOS:
```bash
# Add Cloudflare repository
sudo tee /etc/yum.repos.d/cloudflare-cloudflared.repo <<EOF
[cloudflare-cloudflared]
name=Cloudflare Cloudflared
baseurl=https://pkg.cloudflare.com/cloudflared/rpm/x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF

# Install
sudo yum install cloudflared
```

#### On macOS:
```bash
brew install cloudflare/cloudflare/cloudflared
```

### 2. Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This will open a browser window where you'll need to log in to your Cloudflare account and authorize the Cloudflared application. After authorization, a certificate file will be downloaded to `~/.cloudflared/cert.pem`.

### 3. Create a Tunnel

```bash
cloudflared tunnel create local-ai-cole
```

This command will create a new tunnel and generate a credentials file in `~/.cloudflared/`. The output will show the Tunnel ID and the path to the credentials file.

### 4. Configure the Tunnel

Create a configuration file at `/etc/cloudflared/config.yml`:

```bash
sudo mkdir -p /etc/cloudflared
sudo nano /etc/cloudflared/config.yml
```

Add the following content:

```yaml
# Tunnel ID from the previous step
tunnel: YOUR_TUNNEL_ID
credentials-file: /root/.cloudflared/YOUR_TUNNEL_ID.json

# Ingress rules define how traffic is routed to your services
ingress:
  # Route traffic to Traefik
  - hostname: "*.yourdomain.com"
    service: http://localhost:80
  
  # Default catch-all rule
  - service: http_status:404
```

Copy your credentials file to the system location:

```bash
sudo cp ~/.cloudflared/YOUR_TUNNEL_ID.json /root/.cloudflared/
```

### 5. Configure DNS Records

```bash
cloudflared tunnel route dns YOUR_TUNNEL_ID n8n.yourdomain.com
cloudflared tunnel route dns YOUR_TUNNEL_ID webui.yourdomain.com
cloudflared tunnel route dns YOUR_TUNNEL_ID flowise.yourdomain.com
cloudflared tunnel route dns YOUR_TUNNEL_ID ollama.yourdomain.com
cloudflared tunnel route dns YOUR_TUNNEL_ID supabase.yourdomain.com
cloudflared tunnel route dns YOUR_TUNNEL_ID searxng.yourdomain.com
```

### 6. Run Cloudflared as a Service

```bash
sudo cloudflared service install
```

This will install Cloudflared as a system service and start it automatically.

### 7. Start the Service

```bash
sudo systemctl start cloudflared
```

### 8. Check the Status

```bash
sudo systemctl status cloudflared
```

## Verifying the Setup

1. Check if the tunnel is connected:
   ```bash
   cloudflared tunnel info YOUR_TUNNEL_ID
   ```

2. Check the logs:
   ```bash
   sudo journalctl -u cloudflared
   ```

3. Test the connection by accessing one of your domains in a browser:
   ```
   https://n8n.yourdomain.com
   ```

## Updating Traefik Configuration

Since Cloudflared is now running on the host system, you need to update your Traefik configuration to work with it. Traefik should be configured to listen on port 80 for HTTP traffic.

Update your `traefik.yml` file:

```yaml
entryPoints:
  web:
    address: ":80"
  # Remove websecure entryPoint as SSL is handled by Cloudflare
```

## Troubleshooting

### Tunnel Not Connecting

Check the Cloudflared logs:
```bash
sudo journalctl -u cloudflared
```

### Permission Issues

Make sure the credentials file has the correct permissions:
```bash
sudo chmod 600 /root/.cloudflared/YOUR_TUNNEL_ID.json
```

### Service Not Starting

Check for configuration errors:
```bash
cloudflared tunnel ingress validate
```

## Security Considerations

1. The credentials file contains sensitive information. Keep it secure and restrict access to it.
2. Consider using Cloudflare Access to add an additional layer of authentication to your services.
3. Regularly update Cloudflared to get the latest security patches:
   ```bash
   sudo apt update && sudo apt upgrade cloudflared