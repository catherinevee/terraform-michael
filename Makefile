# Terraform Infrastructure Diagram Generation
# 
# This Makefile provides convenient commands for generating Terraform infrastructure
# diagrams using blast-radius across all environments.

.PHONY: help install check diagrams serve clean docker-diagrams docker-serve

# Default target
help: ## Show this help message
	@echo "Terraform Diagram Generation Commands"
	@echo "======================================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Installation and setup
install: ## Install blast-radius and dependencies
	@echo "Installing blast-radius and dependencies..."
	pip install blastradius
	@echo "Installation complete!"
	@echo "Note: Ensure Graphviz is installed on your system:"
	@echo "  Windows: choco install graphviz"
	@echo "  macOS:   brew install graphviz"
	@echo "  Linux:   sudo apt-get install graphviz"

check: ## Check if all prerequisites are installed
	@echo "Checking prerequisites..."
	@command -v terraform >/dev/null 2>&1 || { echo "ERROR: Terraform not found"; exit 1; }
	@command -v blast-radius >/dev/null 2>&1 || { echo "ERROR: blast-radius not found"; exit 1; }
	@command -v dot >/dev/null 2>&1 || { echo "ERROR: Graphviz not found"; exit 1; }
	@echo "All prerequisites are installed!"

# Diagram generation
diagrams: check ## Generate SVG diagrams for all environments
	@echo "Generating diagrams for all environments..."
	@mkdir -p diagrams
	@$(MAKE) --no-print-directory generate-env ENV=us-west-1/dev NAME=dev-us-west-1
	@$(MAKE) --no-print-directory generate-env ENV=us-west-1/staging NAME=staging-us-west-1
	@$(MAKE) --no-print-directory generate-env ENV=us-west-1/prod NAME=prod-us-west-1
	@$(MAKE) --no-print-directory generate-env ENV=us-west-2/dev NAME=dev-us-west-2
	@echo "All diagrams generated in diagrams/ directory"

generate-env: ## Generate diagram for specific environment (internal target)
	@if [ -d "$(ENV)" ]; then \
		echo "Generating diagram for $(NAME)..."; \
		cd $(ENV) && \
		([ -d ".terraform" ] || terraform init -backend=false >/dev/null 2>&1) && \
		(terraform plan -out=tfplan >/dev/null 2>&1 || echo "Plan failed, using existing state") && \
		blast-radius --svg > ../diagrams/$(NAME).svg 2>/dev/null && \
		rm -f tfplan && \
		echo "Generated: diagrams/$(NAME).svg"; \
	else \
		echo "WARNING: Environment $(ENV) not found, skipping..."; \
	fi

# Interactive server
serve: check ## Start interactive blast-radius server
	@echo "Available environments:"
	@echo "  1. us-west-1/dev"
	@echo "  2. us-west-1/staging"
	@echo "  3. us-west-1/prod"
	@echo "  4. us-west-2/dev"
	@echo ""
	@read -p "Enter environment path (e.g., us-west-1/dev): " env && \
	$(MAKE) --no-print-directory serve-env ENV=$$env

serve-env: ## Start server for specific environment (internal target)
	@if [ -d "$(ENV)" ]; then \
		echo "Starting blast-radius server for $(ENV)..."; \
		cd $(ENV) && \
		([ -d ".terraform" ] || terraform init -backend=false) && \
		terraform plan -out=tfplan && \
		echo "Server starting on http://localhost:5000" && \
		echo "Press Ctrl+C to stop the server" && \
		blast-radius --serve --port 5000; \
	else \
		echo "ERROR: Environment $(ENV) not found"; \
		exit 1; \
	fi

serve-dev: check ## Start server for us-west-1/dev environment
	@$(MAKE) --no-print-directory serve-env ENV=us-west-1/dev

serve-staging: check ## Start server for us-west-1/staging environment
	@$(MAKE) --no-print-directory serve-env ENV=us-west-1/staging

serve-prod: check ## Start server for us-west-1/prod environment
	@$(MAKE) --no-print-directory serve-env ENV=us-west-1/prod

serve-dev-west2: check ## Start server for us-west-2/dev environment
	@$(MAKE) --no-print-directory serve-env ENV=us-west-2/dev

# Docker-based generation
docker-diagrams: ## Generate diagrams using Docker
	@echo "Generating diagrams using Docker..."
	@docker-compose --profile generate up diagram-generator
	@echo "Docker diagram generation complete!"

docker-serve: ## Start blast-radius server using Docker
	@echo "Starting blast-radius server using Docker..."
	@echo "Server will be available at http://localhost:5000"
	@echo "Press Ctrl+C to stop the server"
	@docker-compose up blast-radius

# Environment-specific targets
dev: ## Generate diagram for development environment (us-west-1)
	@$(MAKE) --no-print-directory generate-env ENV=us-west-1/dev NAME=dev-us-west-1

staging: ## Generate diagram for staging environment (us-west-1)
	@$(MAKE) --no-print-directory generate-env ENV=us-west-1/staging NAME=staging-us-west-1

prod: ## Generate diagram for production environment (us-west-1)
	@$(MAKE) --no-print-directory generate-env ENV=us-west-1/prod NAME=prod-us-west-1

dev-west2: ## Generate diagram for development environment (us-west-2)
	@$(MAKE) --no-print-directory generate-env ENV=us-west-2/dev NAME=dev-us-west-2

# Utility targets
clean: ## Clean generated files and temporary data
	@echo "Cleaning generated files..."
	@rm -rf diagrams/*.svg diagrams/*.dot
	@find . -name "tfplan" -delete
	@find . -name ".terraform.lock.hcl" -delete
	@echo "Cleanup complete!"

clean-all: clean ## Clean all generated files including Terraform state
	@echo "Deep cleaning (including .terraform directories)..."
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "Deep cleanup complete!"

# Documentation and validation
validate: ## Validate all Terraform configurations
	@echo "Validating all Terraform configurations..."
	@for env in us-west-1/dev us-west-1/staging us-west-1/prod us-west-2/dev; do \
		if [ -d "$$env" ]; then \
			echo "Validating $$env..."; \
			cd "$$env" && \
			terraform init -backend=false >/dev/null 2>&1 && \
			terraform validate && \
			cd - >/dev/null; \
		fi; \
	done
	@echo "All configurations are valid!"

format: ## Format all Terraform files
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive .
	@echo "Formatting complete!"

# Information targets
info: ## Show project information and statistics
	@echo "Terraform Infrastructure Project Information"
	@echo "==========================================="
	@echo ""
	@echo "Environments:"
	@for env in us-west-1/dev us-west-1/staging us-west-1/prod us-west-2/dev; do \
		if [ -d "$$env" ]; then \
			echo "  EXISTS: $$env"; \
			tf_files=$$(find "$$env" -name "*.tf" | wc -l); \
			echo "     Terraform files: $$tf_files"; \
		else \
			echo "  MISSING: $$env (not found)"; \
		fi; \
	done
	@echo ""
	@echo "Generated diagrams:"
	@if [ -d "diagrams" ]; then \
		for diagram in diagrams/*.svg; do \
			if [ -f "$$diagram" ]; then \
				echo "  DIAGRAM: $$(basename $$diagram)"; \
			fi; \
		done; \
	else \
		echo "  No diagrams generated yet. Run 'make diagrams' to generate."; \
	fi

# Quick commands
quick: diagrams ## Quick generation of all diagrams
	@echo "Quick diagram generation complete!"
	@echo "View diagrams in the diagrams/ directory"

# Advanced targets
update-docs: diagrams ## Update documentation with latest diagrams
	@echo "Updating documentation..."
	@$(MAKE) --no-print-directory generate-index
	@echo "Documentation updated!"

generate-index: ## Generate HTML index for diagrams
	@echo "Generating diagram index..."
	@mkdir -p diagrams
	@cat > diagrams/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Terraform Infrastructure Diagrams</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .diagram { margin: 20px 0; padding: 20px; border: 1px solid #ccc; border-radius: 5px; }
        .env-dev { border-left: 5px solid #3498db; }
        .env-staging { border-left: 5px solid #f39c12; }
        .env-prod { border-left: 5px solid #e74c3c; }
        img { max-width: 100%; height: auto; }
    </style>
</head>
<body>
    <h1>Terraform Infrastructure Diagrams</h1>
    <p>Interactive visualizations of our multi-environment AWS infrastructure.</p>
EOF
	@for svg in diagrams/*.svg; do \
		if [ -f "$$svg" ]; then \
			name=$$(basename "$$svg" .svg); \
			class=""; \
			if echo "$$name" | grep -q "dev"; then class="env-dev"; fi; \
			if echo "$$name" | grep -q "staging"; then class="env-staging"; fi; \
			if echo "$$name" | grep -q "prod"; then class="env-prod"; fi; \
			echo "<div class=\"diagram $$class\">" >> diagrams/index.html; \
			echo "<h2>$$name</h2>" >> diagrams/index.html; \
			echo "<img src=\"$$(basename "$$svg")\" alt=\"$$name diagram\">" >> diagrams/index.html; \
			echo "</div>" >> diagrams/index.html; \
		fi; \
	done
	@echo "<p><small>Generated on $$(date)</small></p>" >> diagrams/index.html
	@echo "</body></html>" >> diagrams/index.html
	@echo "Index generated: diagrams/index.html"

# Development helpers
watch: ## Watch for changes and regenerate diagrams
	@echo "Watching for Terraform file changes..."
	@echo "Press Ctrl+C to stop watching"
	@if command -v fswatch >/dev/null 2>&1; then \
		fswatch -o **/*.tf **/*.tfvars | while read; do \
			echo "Changes detected, regenerating diagrams..."; \
			$(MAKE) --no-print-directory diagrams; \
		done; \
	else \
		echo "ERROR: fswatch not found. Install with:"; \
		echo "  macOS: brew install fswatch"; \
		echo "  Linux: sudo apt-get install fswatch"; \
	fi
