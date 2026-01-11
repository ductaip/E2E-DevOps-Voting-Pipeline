#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting Cloud Native Voting App Deployment...${NC}"

# 1. Dependency Check
echo "Checking dependencies..."

# Docker is critical and external (Docker Desktop)
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: Docker is not running/installed. Please install Docker Desktop first.${NC}"; exit 1; }

# Check for DevOps tools (Terraform, Kind, Kubectl, Helm)
MISSING_TOOLS=false
for tool in terraform kind kubectl helm; do
  if ! command -v $tool >/dev/null 2>&1; then
    MISSING_TOOLS=true
  fi
done

if [ "$MISSING_TOOLS" = true ]; then
  echo -e "${RED}Some tools are missing. Running auto-installer (requires sudo)...${NC}"
  chmod +x install_dependencies.sh
  ./install_dependencies.sh
fi

echo -e "${GREEN}✓ All dependencies ready.${NC}"

# 2. Infrastructure (Terraform)
echo -e "\n${GREEN}🏗️  Provisioning Infrastructure (Kind Cluster)...${NC}"
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# 3. Application (Helm)
echo -e "\n${GREEN}📦 Deploying Voting App (Helm)...${NC}"
# Wait for node to be ready (naive check)
echo "Waiting for cluster to be ready..."
sleep 10
kubectl wait --for=condition=Ready nodes --all --timeout=60s

helm upgrade --install voting-app ./charts/voting-app-chart \
  --set infrastructure.postgres.password=postgres \
  --wait

# 4. Monitoring
echo -e "\n${GREEN}📊 Installing Monitoring Stack...${NC}"
chmod +x monitoring/install.sh
./monitoring/install.sh

echo -e "\n${GREEN}✅ Deployment Complete!${NC}"
echo -e "------------------------------------------------"
echo -e "Vote App   : http://localhost:31000"
echo -e "Result App : http://localhost:31001"
echo -e "Grafana    : http://localhost:3000 (admin/admin)"
echo -e "------------------------------------------------"
