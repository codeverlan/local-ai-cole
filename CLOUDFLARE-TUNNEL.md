# Using Cloudflare Tunnel with Local AI Cole

This guide explains how to use Cloudflare Tunnel to securely expose your Local AI Cole services to the internet with automatic SSL/TLS encryption.

## Benefits of Using Cloudflare Tunnel

- **Secure Access**: All traffic is encrypted and protected by Cloudflare's security features
- **No Port Forwarding**: No need to open ports on your router or firewall
- **Free SSL Certificates**: Automatic SSL/TLS encryption for all your services
- **DDoS Protection**: Built-in protection against DDoS attacks
- **Easy Setup**: Simple configuration with our setup script

## Prerequisites

1. A Cloudflare account (free)
2. A domain managed by Cloudflare
3. Docker and Docker Compose installed on your system

## Setup Instructions

We've provided a setup script that will guide you through the process of setting up a Cloudflare Tunnel for your Local AI Cole services.

1. Run the setup script:
   ```bash
   ./setup-cloudflare-tunnel.sh
   ```

2. Follow the prompts to:
   - Enter your Cloudflare domain
   - Create a Cloudflare Tunnel
   - Configure DNS records for your services

3. Start the services:
   ```bash
   docker-compose -f docker-compose-combined.yml up -d
   ```

## Architecture

The setup consists of the following components:

1. **Traefik**: Acts as a reverse proxy for your services
2. **Cloudflared**: Creates a secure tunnel between your local services and Cloudflare's edge network
3. **Application Services**: N8N, Open WebUI, Flowise, Ollama, etc.

```
Internet → Cloudflare → Cloudflare Tunnel → Cloudflared → Traefik → Your Services
```

## Configuration Files

- `cloudflared/config.yml`: Configuration for the Cloudflare Tunnel
- `docker-compose-cloudflared.yml`: Docker Compose file for running Cloudflared
- `docker-compose-combined.yml`: Combined Docker Compose file for running all services
- `setup-cloudflare-tunnel.sh`: Setup script for configuring the Cloudflare Tunnel

## Troubleshooting

### Tunnel Not Connecting

If your tunnel is not connecting, check the Cloudflared logs:

```bash
docker logs cloudflared
```

### Services Not Accessible

If your services are not accessible through the tunnel, check:

1. Traefik logs:
   ```bash
   docker logs traefik
   ```

2. DNS configuration in Cloudflare dashboard

3. Service logs:
   ```bash
   docker logs <service-name>
   ```

## Customization

You can customize the hostnames for your services by editing the `.env` file:

```
N8N_HOSTNAME=custom-n8n.yourdomain.com
WEBUI_HOSTNAME=custom-webui.yourdomain.com
# etc.
```

## Security Considerations

- All traffic between Cloudflare and your services is encrypted
- You can add Cloudflare Access policies for additional authentication
- Consider enabling Cloudflare Zero Trust features for enhanced security

## Reverting to Local-Only Setup

If you want to revert to a local-only setup without Cloudflare Tunnel:

1. Stop the services:
   ```bash
   docker-compose -f docker-compose-combined.yml down
   ```

2. Start the services with the original docker-compose file:
   ```bash
   docker-compose -f docker-compose-traefik.yml up -d