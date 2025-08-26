.PHONY: help up down logs shell migrate test test-clean env ui-install ui-start ui-dev ui-build ui-dev-start backup-list backup-restore qdrant-restore

NEXT_PUBLIC_USER_ID=$(USER)
NEXT_PUBLIC_API_URL=http://localhost:8765

# Default target
help:
	@echo "Available commands:"
	@echo "  make env       - Copy .env.example to .env"
	@echo "  make up        - Start the containers"
	@echo "  make down      - Stop the containers (creates backup of database and vector store first)"
	@echo "  make logs      - Show container logs"
	@echo "  make shell     - Open a shell in the api container"
	@echo "  make migrate   - Run database migrations"
	@echo "  make test      - Run tests in a new container"
	@echo "  make test-clean - Run tests and clean up volumes"
	@echo "  make backup-list - List available database backups"
	@echo "  make backup-restore BACKUP=<filename> - Restore SQLite database from backup"
	@echo "  make qdrant-restore BACKUP=<filename> - Restore Qdrant vector store from backup"
	@echo "  make ui-install - Install frontend dependencies"
	@echo "  make ui-start  - Start the frontend development server"
	@echo "  make ui-dev    - Install dependencies and start the frontend in dev mode"
	@echo "  make ui        - Install dependencies and start the frontend in production mode"

env:
	cd api && cp .env.example .env
	cd ui && cp .env.example .env

build:
	docker compose build

up:
	NEXT_PUBLIC_USER_ID=$(USER) NEXT_PUBLIC_API_URL=$(NEXT_PUBLIC_API_URL) docker compose up

down:
	@echo "Backing up database and vector store before shutdown..."
	@timestamp=$$(date +%Y%m%d_%H%M%S); \
	mkdir -p api/backups; \
	if [ -f api/openmemory.db ]; then \
		cp api/openmemory.db "api/backups/openmemory_backup_$$timestamp.db"; \
		echo "Database backed up to api/backups/openmemory_backup_$$timestamp.db"; \
	else \
		echo "No database file found to backup"; \
	fi; \
	echo "Backing up Qdrant vector store..."; \
	docker compose exec mem0_store tar -czf /tmp/qdrant_backup_$$timestamp.tar.gz -C /mem0/storage . 2>/dev/null || echo "Qdrant backup failed (container might be down)"; \
	docker cp mem0_store:/tmp/qdrant_backup_$$timestamp.tar.gz "api/backups/" 2>/dev/null || echo "Could not copy Qdrant backup"; \
	if [ -f "api/backups/qdrant_backup_$$timestamp.tar.gz" ]; then \
		echo "Qdrant data backed up to api/backups/qdrant_backup_$$timestamp.tar.gz"; \
	fi
	docker compose down -v
	rm -f api/openmemory.db

logs:
	docker compose logs -f

shell:
	docker compose exec api bash

upgrade:
	docker compose exec api alembic upgrade head

migrate:
	docker compose exec api alembic upgrade head

downgrade:
	docker compose exec api alembic downgrade -1

backup-list:
	@echo "Available database backups:"
	@if [ -d api/backups ]; then \
		echo "SQLite databases:"; \
		ls -la api/backups/*openmemory_backup_*.db 2>/dev/null || echo "  No SQLite backups found"; \
		echo "Qdrant vector stores:"; \
		ls -la api/backups/*qdrant_backup_*.tar.gz 2>/dev/null || echo "  No Qdrant backups found"; \
	else \
		echo "No backup directory found"; \
	fi

backup-restore:
	@if [ -z "$(BACKUP)" ]; then \
		echo "Usage: make backup-restore BACKUP=<filename>"; \
		echo "Available backups:"; \
		make backup-list; \
	else \
		if [ -f "api/backups/$(BACKUP)" ]; then \
			if [[ "$(BACKUP)" == *openmemory_backup_*.db ]]; then \
				cp "api/backups/$(BACKUP)" api/openmemory.db; \
				echo "SQLite database restored from $(BACKUP)"; \
			elif [[ "$(BACKUP)" == *qdrant_backup_*.tar.gz ]]; then \
				echo "To restore Qdrant backup, use: make qdrant-restore BACKUP=$(BACKUP)"; \
			else \
				echo "Unknown backup type: $(BACKUP)"; \
			fi; \
		else \
			echo "Backup file $(BACKUP) not found"; \
			make backup-list; \
		fi; \
	fi

qdrant-restore:
	@if [ -z "$(BACKUP)" ]; then \
		echo "Usage: make qdrant-restore BACKUP=<qdrant_backup_file.tar.gz>"; \
		echo "Available Qdrant backups:"; \
		ls -la api/backups/*qdrant_backup_*.tar.gz 2>/dev/null || echo "No Qdrant backups found"; \
	else \
		if [ -f "api/backups/$(BACKUP)" ]; then \
			if [[ "$(BACKUP)" == *qdrant_backup_*.tar.gz ]]; then \
				echo "Stopping containers to restore Qdrant data..."; \
				docker compose down -v; \
				echo "Starting Qdrant service..."; \
				docker compose up -d mem0_store; \
				sleep 5; \
				echo "Restoring Qdrant data from $(BACKUP)..."; \
				docker cp "api/backups/$(BACKUP)" mem0_store:/tmp/restore.tar.gz; \
				docker compose exec mem0_store sh -c "cd /mem0/storage && tar -xzf /tmp/restore.tar.gz && rm /tmp/restore.tar.gz"; \
				echo "Qdrant data restored from $(BACKUP)"; \
				echo "Starting all services..."; \
				docker compose up -d; \
			else \
				echo "Not a Qdrant backup file: $(BACKUP)"; \
			fi; \
		else \
			echo "Backup file $(BACKUP) not found"; \
		fi; \
	fi

ui-dev:
	cd ui && NEXT_PUBLIC_USER_ID=$(USER) NEXT_PUBLIC_API_URL=$(NEXT_PUBLIC_API_URL) pnpm install && pnpm dev
