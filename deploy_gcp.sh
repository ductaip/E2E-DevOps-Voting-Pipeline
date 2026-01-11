#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}☁️  Initializing Cloud Deployment on GCP VM...${NC}"

# 0. Check for sudo (Root Check)
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root or with sudo"
  echo "Usage: sudo ./deploy_gcp.sh"
  exit 1
fi

# 1. Update System & Install Basics
echo "Updating system..."
apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg make

# 2. Install Docker (If not present)
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group (assumes script run with sudo but we want the actual user)
    # This is tricky in non-interactive. We'll set permissions for the socket for now for simplicity in this session
    chmod 666 /var/run/docker.sock
else
    echo "✓ Docker already installed"
fi

# 3. Install DevOps Tools (Terraform, Kubectl, Helm, Kind)
# Re-use existing script but ensure execute permission
chmod +x install_dependencies.sh
./install_dependencies.sh

# 4. Increase File Watchers (Important for Kind)
echo "fs.inotify.max_user_watches=524288" | tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_instances=512" | tee -a /etc/sysctl.conf
sysctl -p

# 5. Run Deployment
echo -e "${GREEN}🚀 Starting Deployment (Make Up)...${NC}"
# Use runuser to run make as the regular user if $SUDO_USER is set, otherwise run as root.
# Kind config store clusters in user's home, so running as root keeps it in /root/.kube
if [ -n "$SUDO_USER" ]; then
    echo "Running deployment as user: $SUDO_USER"
    runuser -u $SUDO_USER -- make up
else
    make up
fi

echo -e "\n${GREEN}✅ Deployment Finished!${NC}"
echo "To access the apps from outside:"
echo "1. Find your VM External IP."
echo "2. Open Firewall ports 30000-32767 (NodePort range) on GCP Console."
echo "   OR use SSH Tunneling (Recommended):"
echo "   ssh -L 8080:localhost:8080 -L 8081:localhost:8081 -L 3000:localhost:3000 your-user@your-vm-ip"
echo "3. Application URLs (Local/Tunneled):"
echo "   Vote App   : http://localhost:8080"
echo "   Result App : http://localhost:8081"
echo "   Grafana    : http://localhost:3000"
