.PHONY: up down deploy monitoring logs help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Provision infrastructure and deploy everything (One-Shot)
	@./quickstart.sh
	@$(MAKE) build
	@$(MAKE) deploy

build: ## Build and Load Docker images into Kind
	@echo "🐳 Building and Loading images..."
	@docker build -t vote:latest ./vote
	@kind load docker-image vote:latest --name voting-app-cluster
	@docker build -t result:latest ./result
	@kind load docker-image result:latest --name voting-app-cluster
	@docker build -t worker:latest ./worker
	@kind load docker-image worker:latest --name voting-app-cluster

down: ## Destroy the local Kind cluster and cleanup
	@echo "🔥 Destroying Infrastructure..."
	@cd terraform && terraform destroy -auto-approve
	@echo "✅ Cleanup complete."

deploy: ## Update the application (Helm Upgrade)
	@echo "📦 Upgrading Application..."
	@helm upgrade --install voting-app ./charts/voting-app-chart --set infrastructure.postgres.password=postgres

monitoring: ## Install and Access Grafana Dashboard
	@echo "📊 Installing/Verifying Monitoring Stack..."
	@chmod +x monitoring/install.sh && ./monitoring/install.sh

status: ## Check the status of all pods
	@kubectl get pods -A

forward: ## Port-forward Vote (8080) and Result (8081) apps
	@echo "🔗 Forwarding ports..."
	@echo "Vote App: http://localhost:8080"
	@echo "Result App: http://localhost:8081"
	@echo "Grafana: http://localhost:3000 (User: admin / Pass: admin)"
	@echo "(Press Ctrl+C to stop)"
	@kubectl port-forward svc/voting-app-voting-app-chart-vote 8080:80 & \
	kubectl port-forward svc/voting-app-voting-app-chart-result 8081:80 & \
	kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

logs: ## Tail logs for all voting app components
	@kubectl logs -l app.kubernetes.io/instance=voting-app -f --max-log-requests=10
