#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cloudflared Host System Setup for Local AI Cole ===${NC}"
echo -e "${YELLOW}This script will help you set up Cloudflared directly on your host system.${NC}"
echo -e "${YELLOW}You'll need a Cloudflare account and a domain managed by Cloudflare.${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (sudo).${NC}"
  exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VERSION=$VERSION_ID
else
    echo -e "${RED}Cannot detect OS. Please install Cloudflared manually.${NC}"
    exit 1
fi

# Install Cloudflared based on OS
echo -e "${BLUE}Step 1: Installing Cloudflared${NC}"

if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    echo -e "${YELLOW}Detected $OS $VERSION. Installing Cloudflared...${NC}"
    
    # Add Cloudflare GPG key
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    
    # Add Cloudflare repository
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflared.list
    
    # Update and install
    apt update
    apt install -y cloudflared
    
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
    echo -e "${YELLOW}Detected $OS $VERSION. Installing Cloudflared...${NC}"
    
    # Add Cloudflare repository
    tee /etc/yum.repos.d/cloudflare-cloudflared.repo <<EOF
[cloudflare-cloudflared]
name=Cloudflare Cloudflared
baseurl=https://pkg.cloudflare.com/cloudflared/rpm/x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF
    
    # Install
    yum install -y cloudflared
    
else
    echo -e "${RED}Unsupported OS: $OS. Please install Cloudflared manually.${NC}"
    exit 1
fi

echo -e "${GREEN}Cloudflared installed successfully.${NC}\n"

# Create .env file if it doesn't exist
if [ ! -f /home/tbwyler/local-ai-cole/.env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    touch /home/tbwyler/local-ai-cole/.env
fi

# Ask for domain
echo -e "${BLUE}Step 2: Domain Configuration${NC}"
read -p "Enter your Cloudflare domain (e.g., example.com): " DOMAIN
echo "DOMAIN=$DOMAIN" >> /home/tbwyler/local-ai-cole/.env
echo -e "${GREEN}Domain saved to .env file.${NC}\n"

# Set default service hostnames
echo "N8N_HOSTNAME=n8n.$DOMAIN" >> /home/tbwyler/local-ai-cole/.env
echo "WEBUI_HOSTNAME=webui.$DOMAIN" >> /home/tbwyler/local-ai-cole/.env
echo "FLOWISE_HOSTNAME=flowise.$DOMAIN" >> /home/tbwyler/local-ai-cole/.env
echo "OLLAMA_HOSTNAME=ollama.$DOMAIN" >> /home/tbwyler/local-ai-cole/.env
echo "SUPABASE_HOSTNAME=supabase.$DOMAIN" >> /home/tbwyler/local-ai-cole/.env
echo "SEARXNG_HOSTNAME=searxng.$DOMAIN" >> /home/tbwyler/local-ai-cole/.env

echo -e "${GREEN}Default service hostnames saved to .env file.${NC}\n"

# Create directories
echo -e "${BLUE}Step 3: Creating Directories${NC}"
mkdir -p /etc/cloudflared
mkdir -p /root/.cloudflared
echo -e "${GREEN}Directories created.${NC}\n"

# Guide for authentication
echo -e "${BLUE}Step 4: Authenticate with Cloudflare${NC}"
echo -e "${YELLOW}You need to authenticate with Cloudflare. This will open a browser window.${NC}"
echo -e "${YELLOW}After authentication, a certificate file will be downloaded to ~/.cloudflared/cert.pem${NC}"
read -p "Press Enter to continue..."

# Run authentication
cloudflared tunnel login

# Check if authentication was successful
if [ ! -f ~/.cloudflared/cert.pem ]; then
    echo -e "${RED}Authentication failed. Please try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Authentication successful.${NC}\n"

# Create tunnel
echo -e "${BLUE}Step 5: Create a Tunnel${NC}"
TUNNEL_NAME="local-ai-cole"
TUNNEL_OUTPUT=$(cloudflared tunnel create $TUNNEL_NAME)
TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oP 'Created tunnel \K[a-z0-9-]+')

if [ -z "$TUNNEL_ID" ]; then
    echo -e "${RED}Failed to create tunnel. Please check the output and try again.${NC}"
    exit 1
fi

echo "CLOUDFLARE_TUNNEL_ID=$TUNNEL_ID" >> /home/tbwyler/local-ai-cole/.env
echo -e "${GREEN}Tunnel created with ID: $TUNNEL_ID${NC}\n"

# Copy credentials file
CRED_FILE=$(find ~/.cloudflared -name "$TUNNEL_ID.json")
if [ -z "$CRED_FILE" ]; then
    echo -e "${RED}Credentials file not found. Please check ~/.cloudflared/ directory.${NC}"
    exit 1
fi

cp $CRED_FILE /root/.cloudflared/
chmod 600 /root/.cloudflared/$TUNNEL_ID.json
echo -e "${GREEN}Credentials file copied to /root/.cloudflared/${NC}\n"

# Create config file
echo -e "${BLUE}Step 6: Creating Configuration File${NC}"
cat > /etc/cloudflared/config.yml << EOF
# Cloudflared configuration file
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

# Ingress rules define how traffic is routed to your services
ingress:
  # Route traffic to Traefik
  - hostname: "*.$DOMAIN"
    service: http://localhost:80
  
  # Default catch-all rule
  - service: http_status:404
EOF

echo -e "${GREEN}Configuration file created at /etc/cloudflared/config.yml${NC}\n"

# Configure DNS
echo -e "${BLUE}Step 7: Configuring DNS Records${NC}"
echo -e "${YELLOW}Creating DNS records for your services...${NC}"

cloudflared tunnel route dns $TUNNEL_ID n8n.$DOMAIN
cloudflared tunnel route dns $TUNNEL_ID webui.$DOMAIN
cloudflared tunnel route dns $TUNNEL_ID flowise.$DOMAIN
cloudflared tunnel route dns $TUNNEL_ID ollama.$DOMAIN
cloudflared tunnel route dns $TUNNEL_ID supabase.$DOMAIN
cloudflared tunnel route dns $TUNNEL_ID searxng.$DOMAIN

echo -e "${GREEN}DNS records created.${NC}\n"

# Install as a service
echo -e "${BLUE}Step 8: Installing Cloudflared as a Service${NC}"
cloudflared service install
systemctl enable cloudflared
systemctl start cloudflared

echo -e "${GREEN}Cloudflared service installed and started.${NC}\n"

# Check service status
echo -e "${BLUE}Step 9: Checking Service Status${NC}"
systemctl status cloudflared

echo -e "\n${BLUE}Step 10: Verifying Tunnel Connection${NC}"
cloudflared tunnel info $TUNNEL_ID

echo -e "\n${GREEN}Setup complete! Your services will be available at:${NC}"
echo -e "- N8N: https://n8n.$DOMAIN"
echo -e "- Web UI: https://webui.$DOMAIN"
echo -e "- Flowise: https://flowise.$DOMAIN"
echo -e "- Ollama: https://ollama.$DOMAIN"
echo -e "- Supabase: https://supabase.$DOMAIN"
echo -e "- SearXNG: https://searxng.$DOMAIN"

echo -e "\n${YELLOW}Note: You need to start Traefik and your services separately:${NC}"
echo -e "cd /home/tbwyler/local-ai-cole && docker-compose -f docker-compose-traefik.yml up -d"