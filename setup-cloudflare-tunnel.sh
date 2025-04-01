#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cloudflare Tunnel Setup for Local AI Cole ===${NC}"
echo -e "${YELLOW}This script will help you set up a Cloudflare Tunnel to securely expose your services to the internet.${NC}"
echo -e "${YELLOW}You'll need a Cloudflare account and a domain managed by Cloudflare.${NC}\n"

# Check if .env file exists, create if not
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    touch .env
fi

# Ask for domain
echo -e "${BLUE}Step 1: Domain Configuration${NC}"
read -p "Enter your Cloudflare domain (e.g., example.com): " DOMAIN
echo "DOMAIN=$DOMAIN" >> .env
echo -e "${GREEN}Domain saved to .env file.${NC}\n"

# Guide for creating a Cloudflare Tunnel
echo -e "${BLUE}Step 2: Create a Cloudflare Tunnel${NC}"
echo -e "${YELLOW}Please follow these steps to create a Cloudflare Tunnel:${NC}"
echo -e "1. Log in to your Cloudflare dashboard at https://dash.cloudflare.com"
echo -e "2. Select your domain: $DOMAIN"
echo -e "3. Go to 'Zero Trust' > 'Access' > 'Tunnels'"
echo -e "4. Click 'Create a tunnel'"
echo -e "5. Give your tunnel a name (e.g., 'local-ai-cole')"
echo -e "6. In the 'Install connector' step, select 'Docker' and copy the token"
echo -e "7. Do NOT proceed to the next step in Cloudflare yet\n"

# Ask for Cloudflare Tunnel Token
read -p "Enter your Cloudflare Tunnel Token: " CLOUDFLARE_TUNNEL_TOKEN
echo "CLOUDFLARE_TUNNEL_TOKEN=$CLOUDFLARE_TUNNEL_TOKEN" >> .env
echo -e "${GREEN}Tunnel Token saved to .env file.${NC}\n"

# Extract Tunnel ID from the token
CLOUDFLARE_TUNNEL_ID=$(echo $CLOUDFLARE_TUNNEL_TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq -r .tid)
if [ -z "$CLOUDFLARE_TUNNEL_ID" ]; then
    echo -e "${RED}Failed to extract Tunnel ID from token. Please make sure you entered the correct token.${NC}"
    echo -e "${YELLOW}You'll need to manually set CLOUDFLARE_TUNNEL_ID in your .env file.${NC}"
    read -p "Enter your Cloudflare Tunnel ID: " CLOUDFLARE_TUNNEL_ID
fi
echo "CLOUDFLARE_TUNNEL_ID=$CLOUDFLARE_TUNNEL_ID" >> .env
echo -e "${GREEN}Tunnel ID saved to .env file.${NC}\n"

# Create credentials directory if it doesn't exist
mkdir -p cloudflared

# Guide for DNS configuration
echo -e "${BLUE}Step 3: Configure DNS Records${NC}"
echo -e "${YELLOW}Now, go back to the Cloudflare dashboard and continue with the tunnel setup:${NC}"
echo -e "1. In the 'Public Hostname' tab, add the following hostnames:"
echo -e "   - n8n.$DOMAIN pointing to localhost:80"
echo -e "   - webui.$DOMAIN pointing to localhost:80"
echo -e "   - flowise.$DOMAIN pointing to localhost:80"
echo -e "   - ollama.$DOMAIN pointing to localhost:80"
echo -e "   - supabase.$DOMAIN pointing to localhost:80"
echo -e "   - searxng.$DOMAIN pointing to localhost:80"
echo -e "2. Click 'Save' to complete the tunnel setup\n"

# Set default service hostnames
echo "N8N_HOSTNAME=n8n.$DOMAIN" >> .env
echo "WEBUI_HOSTNAME=webui.$DOMAIN" >> .env
echo "FLOWISE_HOSTNAME=flowise.$DOMAIN" >> .env
echo "OLLAMA_HOSTNAME=ollama.$DOMAIN" >> .env
echo "SUPABASE_HOSTNAME=supabase.$DOMAIN" >> .env
echo "SEARXNG_HOSTNAME=searxng.$DOMAIN" >> .env

echo -e "${GREEN}Default service hostnames saved to .env file.${NC}\n"

echo -e "${BLUE}Step 4: Start the Services${NC}"
echo -e "${YELLOW}You can now start the services with:${NC}"
echo -e "docker-compose -f docker-compose-combined.yml up -d\n"

echo -e "${GREEN}Setup complete! Your services will be available at:${NC}"
echo -e "- N8N: https://n8n.$DOMAIN"
echo -e "- Web UI: https://webui.$DOMAIN"
echo -e "- Flowise: https://flowise.$DOMAIN"
echo -e "- Ollama: https://ollama.$DOMAIN"
echo -e "- Supabase: https://supabase.$DOMAIN"
echo -e "- SearXNG: https://searxng.$DOMAIN"