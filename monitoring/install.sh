#!/bin/bash
set -e

# Add Prometheus Community Helm Repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring || true

# Install kube-prometheus-stack
# This includes Prometheus, Grafana, Alertmanager, and Node Exporter
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword='admin' \
  --wait

echo "Monitoring Stack Installed."
echo "Access Grafana:"
echo "kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80"
echo "Open http://localhost:3000 (User: admin, Pass: admin)"
