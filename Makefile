.PHONY: help setup start stop restart logs clean build test health status

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show this help message
	@echo "$(GREEN)Online Banking Microservices - Quick Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

setup: ## Full setup with build (first time)
	@echo "$(GREEN)Running full setup...$(NC)"
	@chmod +x setup.sh
	@./setup.sh

start: ## Start services (skip build)
	@echo "$(GREEN)Starting services...$(NC)"
	@chmod +x setup.sh
	@./setup.sh --skip-build

stop: ## Stop all services
	@echo "$(YELLOW)Stopping services...$(NC)"
	@chmod +x cleanup.sh
	@./cleanup.sh --stop

restart: stop start ## Restart all services

logs: ## View logs from all services
	@docker-compose logs -f

logs-service: ## View logs from specific service (usage: make logs-service SERVICE=auth-service)
	@docker-compose logs -f $(SERVICE)

clean: ## Remove containers (keep data)
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@chmod +x cleanup.sh
	@./cleanup.sh --remove

clean-all: ## Remove everything including data
	@echo "$(RED)Warning: This will delete all data!$(NC)"
	@chmod +x cleanup.sh
	@./cleanup.sh --full

build: ## Build all Docker images
	@echo "$(GREEN)Building images...$(NC)"
	@docker-compose build

build-service: ## Build specific service (usage: make build-service SERVICE=auth-service)
	@echo "$(GREEN)Building $(SERVICE)...$(NC)"
	@docker-compose build $(SERVICE)

test: ## Run tests
	@echo "$(GREEN)Running tests...$(NC)"
	@cd services/auth && mvn test
	@cd services/account && mvn test
	@cd services/transaction && mvn test
	@cd services/loan && mvn test
	@cd services/notification && mvn test

health: ## Check service health
	@echo "$(GREEN)Checking service health...$(NC)"
	@chmod +x setup.sh
	@./setup.sh --health-check

status: ## Show service status
	@echo "$(GREEN)Service Status:$(NC)"
	@docker-compose ps
	@echo ""
	@echo "$(GREEN)Docker Resources:$(NC)"
	@docker system df

eureka: ## Open Eureka dashboard
	@echo "$(GREEN)Opening Eureka dashboard...$(NC)"
	@xdg-open http://localhost:8761 2>/dev/null || open http://localhost:8761 2>/dev/null || echo "Open http://localhost:8761 in your browser"

swagger: ## Open Swagger aggregator
	@echo "$(GREEN)Opening Swagger aggregator...$(NC)"
	@xdg-open http://localhost:8222/swagger-aggregator.html 2>/dev/null || open http://localhost:8222/swagger-aggregator.html 2>/dev/null || echo "Open http://localhost:8222/swagger-aggregator.html in your browser"

gateway: ## Open API Gateway
	@echo "$(GREEN)Opening API Gateway...$(NC)"
	@xdg-open http://localhost:8222 2>/dev/null || open http://localhost:8222 2>/dev/null || echo "Open http://localhost:8222 in your browser"

db-psql: ## Connect to PostgreSQL
	@docker exec -it ms_pg_sql psql -U postgres

db-list: ## List all databases
	@docker exec ms_pg_sql psql -U postgres -c "\l"

db-backup: ## Backup all databases
	@echo "$(GREEN)Backing up databases...$(NC)"
	@docker exec ms_pg_sql pg_dumpall -U postgres > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)Backup complete!$(NC)"

db-restore: ## Restore from backup (usage: make db-restore FILE=backup.sql)
	@echo "$(YELLOW)Restoring from $(FILE)...$(NC)"
	@docker exec -i ms_pg_sql psql -U postgres < $(FILE)
	@echo "$(GREEN)Restore complete!$(NC)"

update: ## Update and restart (pull latest code)
	@echo "$(GREEN)Updating application...$(NC)"
	@git pull
	@$(MAKE) clean
	@$(MAKE) setup

prune: ## Clean up Docker system
	@echo "$(YELLOW)Pruning Docker system...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)Cleanup complete!$(NC)"
