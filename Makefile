.PHONY: build up down clean

# Default target
all: build

# Build the Docker image
build:
	docker build -t secret-contract-verifier .

# Start the services
up:
	docker compose up -d

# Rebuild and start the services
up-build:
	docker compose up -d --build

# Stop the services
down:
	docker compose down

# Stop the services and remove volumes
down-v:
	docker compose down -v

# Remove built images
clean:
	docker rmi secret-contract-verifier

# Show logs
logs:
	docker compose logs -f

# Enter the container shell
shell:
	docker compose exec contract-verifier bash

# Help information
help:
	@echo "Makefile for secret-contract-verifier"
	@echo ""
	@echo "Usage:"
	@echo "  make build     - Build the Docker image"
	@echo "  make up        - Start the services"
	@echo "  make up-build  - Rebuild and start the services"
	@echo "  make down      - Stop the services"
	@echo "  make down-v    - Stop services and remove volumes"
	@echo "  make clean     - Remove built images"
	@echo "  make logs      - Show service logs"
	@echo "  make shell     - Open a shell in the contract-verifier container" 
