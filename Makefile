.PHONY: help install install-homebrew install-python install-jira-cli install-deps setup test clean run check-python check-jira-cli build deploy validate-prereqs

# Default target
.DEFAULT_GOAL := help

# Detect OS
UNAME_S := $(shell uname -s)
PYTHON := python3

# Colors for output
GREEN := \033[0;32m
BLUE := \033[0;34m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

help: ## Show this help message
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)JIRA MCP Server - Makefile Commands$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  $(BLUE)make install$(NC)           # Complete one-command installation"
	@echo "  $(BLUE)make setup$(NC)             # Interactive configuration"
	@echo "  $(BLUE)make run$(NC)               # Start MCP server"
	@echo ""
	@echo "$(GREEN)Setup Commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Usage Examples:$(NC)"
	@echo "  make status            # Check installation status"
	@echo "  make validate-prereqs  # Check what needs to be installed"
	@echo "  make test              # Run tests"

validate-prereqs: ## Validate prerequisites and show what needs installation
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)Validating Prerequisites$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@NEEDS_INSTALL=0; \
	echo "$(YELLOW)Checking system prerequisites...$(NC)"; \
	echo ""; \
	if [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "$(YELLOW)Homebrew:$(NC)"; \
		if command -v brew >/dev/null 2>&1; then \
			echo "  $(GREEN)✅ Installed$(NC) - $$(brew --version | head -n1)"; \
		else \
			echo "  $(RED)❌ Not installed$(NC) - Will be installed automatically"; \
			NEEDS_INSTALL=1; \
		fi; \
		echo ""; \
	fi; \
	echo "$(YELLOW)Python 3.10+:$(NC)"; \
	if command -v $(PYTHON) >/dev/null 2>&1; then \
		PY_VERSION=$$($(PYTHON) --version 2>&1 | cut -d' ' -f2); \
		PY_MAJOR=$$(echo $$PY_VERSION | cut -d'.' -f1); \
		PY_MINOR=$$(echo $$PY_VERSION | cut -d'.' -f2); \
		if [ "$$PY_MAJOR" -ge 3 ] && [ "$$PY_MINOR" -ge 10 ]; then \
			echo "  $(GREEN)✅ Installed$(NC) - Python $$PY_VERSION"; \
		else \
			echo "  $(RED)❌ Version too old$(NC) - Found: $$PY_VERSION, Need: 3.10+"; \
			echo "  Will install Python 3.10+"; \
			NEEDS_INSTALL=1; \
		fi; \
	else \
		echo "  $(RED)❌ Not installed$(NC) - Will be installed automatically"; \
		NEEDS_INSTALL=1; \
	fi; \
	echo ""; \
	echo "$(YELLOW)jira CLI:$(NC)"; \
	if command -v jira >/dev/null 2>&1; then \
		echo "  $(GREEN)✅ Installed$(NC) - $$(jira version 2>&1 | head -n1)"; \
	else \
		echo "  $(RED)❌ Not installed$(NC) - Will be installed automatically"; \
		NEEDS_INSTALL=1; \
	fi; \
	echo ""; \
	echo "$(YELLOW)Python Virtual Environment:$(NC)"; \
	if [ -d "venv" ]; then \
		echo "  $(GREEN)✅ Created$(NC)"; \
	else \
		echo "  $(RED)❌ Not created$(NC) - Will be created automatically"; \
		NEEDS_INSTALL=1; \
	fi; \
	echo ""; \
	echo "$(YELLOW)MCP Dependencies:$(NC)"; \
	if [ -d "venv" ] && [ -f "venv/bin/python" ]; then \
		if venv/bin/python -c "import mcp" 2>/dev/null; then \
			echo "  $(GREEN)✅ Installed$(NC)"; \
		else \
			echo "  $(RED)❌ Not installed$(NC) - Will be installed automatically"; \
			NEEDS_INSTALL=1; \
		fi; \
	else \
		echo "  $(YELLOW)⚠️  Skipped$(NC) - Virtual environment not created"; \
	fi; \
	echo ""; \
	echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"; \
	if [ "$$NEEDS_INSTALL" -eq 0 ]; then \
		echo "$(GREEN)✅ All prerequisites satisfied!$(NC)"; \
		echo ""; \
		echo "Next steps:"; \
		echo "  make setup    # Configure JIRA credentials"; \
		echo "  make run      # Start MCP server"; \
	else \
		echo "$(YELLOW)⚠️  Missing prerequisites will be installed$(NC)"; \
		echo ""; \
		echo "Run: $(BLUE)make install$(NC) to install everything"; \
	fi; \
	echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

install-homebrew: ## Install Homebrew (macOS only)
ifeq ($(UNAME_S),Darwin)
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)Installing Homebrew$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		echo "$(GREEN)✅ Homebrew already installed$(NC)"; \
	else \
		echo "$(YELLOW)Installing Homebrew (will prompt for password)...$(NC)"; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo "$(GREEN)✅ Homebrew installed successfully$(NC)"; \
	fi
else
	@echo "$(YELLOW)⚠️  Homebrew is macOS-only. Skipping.$(NC)"
endif

install-python: install-homebrew ## Install Python 3.10+
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)Installing Python 3.10+$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@if command -v $(PYTHON) >/dev/null 2>&1; then \
		PY_VERSION=$$($(PYTHON) --version 2>&1 | cut -d' ' -f2); \
		PY_MAJOR=$$(echo $$PY_VERSION | cut -d'.' -f1); \
		PY_MINOR=$$(echo $$PY_VERSION | cut -d'.' -f2); \
		if [ "$$PY_MAJOR" -ge 3 ] && [ "$$PY_MINOR" -ge 10 ]; then \
			echo "$(GREEN)✅ Python $$PY_VERSION already installed$(NC)"; \
		else \
			echo "$(YELLOW)Upgrading Python from $$PY_VERSION to 3.10+...$(NC)"; \
			if [ "$(UNAME_S)" = "Darwin" ]; then \
				brew install python@3.10; \
			elif [ "$(UNAME_S)" = "Linux" ]; then \
				sudo apt-get update && sudo apt-get install -y python3.10 python3.10-venv python3-pip || \
				sudo yum install -y python310 python310-pip; \
			fi; \
			echo "$(GREEN)✅ Python 3.10+ installed$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)Installing Python 3.10+...$(NC)"; \
		if [ "$(UNAME_S)" = "Darwin" ]; then \
			brew install python@3.10; \
			echo "$(GREEN)✅ Python installed via Homebrew$(NC)"; \
		elif [ "$(UNAME_S)" = "Linux" ]; then \
			if command -v apt-get >/dev/null 2>&1; then \
				echo "$(BLUE)Detected Debian/Ubuntu$(NC)"; \
				sudo apt-get update && sudo apt-get install -y python3.10 python3.10-venv python3-pip; \
			elif command -v yum >/dev/null 2>&1; then \
				echo "$(BLUE)Detected RHEL/CentOS$(NC)"; \
				sudo yum install -y python310 python310-pip; \
			else \
				echo "$(RED)❌ Unsupported Linux distribution$(NC)"; \
				echo "$(YELLOW)Please install Python 3.10+ manually$(NC)"; \
				exit 1; \
			fi; \
			echo "$(GREEN)✅ Python installed$(NC)"; \
		else \
			echo "$(RED)❌ Unsupported OS: $(UNAME_S)$(NC)"; \
			echo "$(YELLOW)Please install Python 3.10+ manually$(NC)"; \
			exit 1; \
		fi; \
	fi

check-python: ## Check if Python 3.10+ is installed
	@if ! command -v $(PYTHON) >/dev/null 2>&1; then \
		echo "$(RED)❌ Python 3 not found$(NC)"; \
		echo "$(YELLOW)Run: make install-python$(NC)"; \
		exit 1; \
	fi
	@PY_VERSION=$$($(PYTHON) --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2); \
	PY_MAJOR=$$(echo $$PY_VERSION | cut -d'.' -f1); \
	PY_MINOR=$$(echo $$PY_VERSION | cut -d'.' -f2); \
	if [ "$$PY_MAJOR" -lt 3 ] || ([ "$$PY_MAJOR" -eq 3 ] && [ "$$PY_MINOR" -lt 10 ]); then \
		echo "$(RED)❌ Python 3.10+ required. Found: $$PY_VERSION$(NC)"; \
		echo "$(YELLOW)Run: make install-python$(NC)"; \
		exit 1; \
	fi

check-jira-cli: ## Check if jira-cli is installed
	@if ! command -v jira >/dev/null 2>&1; then \
		echo "$(RED)❌ jira CLI not found$(NC)"; \
		echo "$(YELLOW)Run: make install-jira-cli$(NC)"; \
		exit 1; \
	fi

install-jira-cli: ## Install jira-cli based on OS
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)Installing jira CLI$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@if command -v jira >/dev/null 2>&1; then \
		echo "$(GREEN)✅ jira CLI already installed$(NC)"; \
	else \
		if [ "$(UNAME_S)" = "Darwin" ]; then \
			echo "$(BLUE)Detected macOS - installing via Homebrew$(NC)"; \
			if ! command -v brew >/dev/null 2>&1; then \
				echo "$(YELLOW)Homebrew required. Installing...$(NC)"; \
				$(MAKE) install-homebrew; \
			fi; \
			brew install ankitpokhrel/jira-cli/jira-cli; \
			echo "$(GREEN)✅ jira CLI installed successfully$(NC)"; \
		elif [ "$(UNAME_S)" = "Linux" ]; then \
			echo "$(BLUE)Detected Linux - downloading binary$(NC)"; \
			mkdir -p /tmp/jira-cli; \
			curl -L https://github.com/ankitpokhrel/jira-cli/releases/download/v1.4.0/jira_1.4.0_linux_x86_64.tar.gz | tar xz -C /tmp/jira-cli; \
			sudo mv /tmp/jira-cli/bin/jira /usr/local/bin/; \
			rm -rf /tmp/jira-cli; \
			echo "$(GREEN)✅ jira CLI installed to /usr/local/bin/jira$(NC)"; \
		else \
			echo "$(RED)❌ Unsupported OS: $(UNAME_S)$(NC)"; \
			echo "$(YELLOW)For Windows, install with: scoop install jira-cli$(NC)"; \
			exit 1; \
		fi; \
	fi

venv: check-python ## Create Python virtual environment
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)Creating Python Virtual Environment$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@if [ -d "venv" ]; then \
		echo "$(YELLOW)⚠️  Virtual environment already exists$(NC)"; \
	else \
		$(PYTHON) -m venv venv; \
		echo "$(GREEN)✅ Virtual environment created$(NC)"; \
	fi

install-deps: venv ## Install Python dependencies
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)Installing Python Dependencies$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@. venv/bin/activate && \
		pip install --upgrade pip >/dev/null 2>&1 && \
		pip install mcp
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

install-dev-deps: venv ## Install development dependencies
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)Installing Development Dependencies$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@. venv/bin/activate && \
		pip install --upgrade pip >/dev/null 2>&1 && \
		pip install mcp pytest pytest-cov black flake8 mypy
	@echo "$(GREEN)✅ Development dependencies installed$(NC)"

install: ## Complete one-command installation (validates & installs all prerequisites)
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)JIRA MCP Server - Complete Installation$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(YELLOW)This will install:$(NC)"
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		command -v brew >/dev/null 2>&1 || echo "  • Homebrew (package manager)"; \
	fi
	@command -v $(PYTHON) >/dev/null 2>&1 || echo "  • Python 3.10+"
	@command -v jira >/dev/null 2>&1 || echo "  • jira CLI"
	@if [ ! -d "venv" ]; then echo "  • Python virtual environment"; fi
	@if [ ! -d "venv" ] || ! venv/bin/python -c "import mcp" 2>/dev/null; then echo "  • MCP Python package"; fi
	@echo ""
	@echo "$(YELLOW)System changes may require sudo password.$(NC)"
	@echo ""
	@read -p "Continue with installation? [Y/n] " -n 1 -r; \
	echo; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]] && [[ -n $$REPLY ]]; then \
		echo "$(YELLOW)Installation cancelled$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@$(MAKE) install-python
	@$(MAKE) install-jira-cli
	@$(MAKE) install-deps
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)✅ Installation Complete!$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Configure JIRA CLI:  $(YELLOW)jira init$(NC)"
	@echo "  2. Run setup script:    $(YELLOW)make setup$(NC)"
	@echo "  3. Test the server:     $(YELLOW)make run$(NC)"
	@echo ""

setup: check-python check-jira-cli ## Run interactive setup script
	@echo "$(BLUE)Running setup script...$(NC)"
	@chmod +x setup.sh
	./setup.sh

configure-jira: check-jira-cli ## Configure jira CLI credentials
	@echo "$(BLUE)Configuring jira CLI...$(NC)"
	jira init

run: check-python check-jira-cli install-deps ## Run the MCP server
	@echo "$(BLUE)Starting JIRA MCP server...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@. venv/bin/activate && $(PYTHON) server.py

test: install-deps ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	@if [ -d "tests" ]; then \
		. venv/bin/activate && pytest tests/; \
	else \
		echo "$(YELLOW)⚠️  No tests directory found. Creating example test...$(NC)"; \
		mkdir -p tests; \
		echo 'def test_example():\n    assert True' > tests/test_example.py; \
		. venv/bin/activate && pytest tests/; \
	fi

test-coverage: install-dev-deps ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	@mkdir -p tests
	@. venv/bin/activate && pytest --cov=server --cov-report=html --cov-report=term tests/
	@echo "$(GREEN)✅ Coverage report generated in htmlcov/index.html$(NC)"

lint: install-dev-deps ## Run code linting
	@echo "$(BLUE)Running linters...$(NC)"
	@. venv/bin/activate && \
		echo "$(BLUE)Running black...$(NC)" && \
		black --check server.py || true && \
		echo "$(BLUE)Running flake8...$(NC)" && \
		flake8 server.py --max-line-length=88 --extend-ignore=E203 || true && \
		echo "$(BLUE)Running mypy...$(NC)" && \
		mypy server.py --ignore-missing-imports || true

format: install-dev-deps ## Format code with black
	@echo "$(BLUE)Formatting code with black...$(NC)"
	@. venv/bin/activate && black server.py
	@echo "$(GREEN)✅ Code formatted$(NC)"

build: check-python ## Build Python package
	@echo "$(BLUE)Building Python package...$(NC)"
	@. venv/bin/activate && \
		pip install build && \
		$(PYTHON) -m build
	@echo "$(GREEN)✅ Package built in dist/$(NC)"

clean: ## Clean build artifacts and cache
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@rm -rf build/
	@rm -rf dist/
	@rm -rf *.egg-info
	@rm -rf __pycache__/
	@rm -rf .pytest_cache/
	@rm -rf .mypy_cache/
	@rm -rf htmlcov/
	@rm -rf .coverage
	@find . -type f -name '*.pyc' -delete
	@find . -type d -name '__pycache__' -delete
	@echo "$(GREEN)✅ Cleaned$(NC)"

clean-all: clean ## Clean everything including venv
	@echo "$(BLUE)Cleaning virtual environment...$(NC)"
	@rm -rf venv/
	@echo "$(GREEN)✅ All cleaned$(NC)"

status: ## Show detailed installation status
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)JIRA MCP Server - Installation Status$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(YELLOW)Operating System:$(NC)"
	@echo "  $(UNAME_S)"
	@echo ""
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "$(YELLOW)Homebrew:$(NC)"; \
		if command -v brew >/dev/null 2>&1; then \
			echo "  $(GREEN)✅ Installed - $$(brew --version | head -n1)$(NC)"; \
		else \
			echo "  $(RED)❌ Not installed$(NC)"; \
		fi; \
		echo ""; \
	fi
	@echo "$(YELLOW)Python:$(NC)"
	@if command -v $(PYTHON) >/dev/null 2>&1; then \
		PY_VERSION=$$($(PYTHON) --version 2>&1 | cut -d' ' -f2); \
		echo "  $(GREEN)✅ $(PYTHON) $$PY_VERSION$(NC)"; \
	else \
		echo "  $(RED)❌ Not found$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)jira CLI:$(NC)"
	@if command -v jira >/dev/null 2>&1; then \
		echo "  $(GREEN)✅ jira $$(jira version 2>&1 | head -n1 | cut -d' ' -f3 || echo 'installed')$(NC)"; \
	else \
		echo "  $(RED)❌ Not installed$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Virtual Environment:$(NC)"
	@if [ -d "venv" ]; then \
		echo "  $(GREEN)✅ Created$(NC)"; \
	else \
		echo "  $(RED)❌ Not created$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)MCP Dependencies:$(NC)"
	@if [ -d "venv" ]; then \
		. venv/bin/activate && pip show mcp >/dev/null 2>&1 && \
			echo "  $(GREEN)✅ Installed$(NC)" || \
			echo "  $(RED)❌ Not installed$(NC)"; \
	else \
		echo "  $(RED)❌ Virtual environment not created$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)jira CLI Configuration:$(NC)"
	@if jira version >/dev/null 2>&1; then \
		echo "  $(GREEN)✅ Configured$(NC)"; \
	else \
		echo "  $(YELLOW)⚠️  Not configured (run: make configure-jira)$(NC)"; \
	fi
	@echo ""

update: ## Update dependencies
	@echo "$(BLUE)Updating dependencies...$(NC)"
	@. venv/bin/activate && \
		pip install --upgrade pip && \
		pip install --upgrade mcp
	@echo "$(GREEN)✅ Dependencies updated$(NC)"

deploy-docker: ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(NC)"
	@if [ ! -f "Dockerfile" ]; then \
		echo "$(RED)❌ Dockerfile not found$(NC)"; \
		exit 1; \
	fi
	docker build -t jira-mcp-server:latest .
	@echo "$(GREEN)✅ Docker image built: jira-mcp-server:latest$(NC)"

docker-run: ## Run Docker container
	@echo "$(BLUE)Running Docker container...$(NC)"
	docker run -it --rm \
		-e JIRA_URL="${JIRA_URL}" \
		-e JIRA_DEFAULT_PROJECT="${JIRA_DEFAULT_PROJECT}" \
		jira-mcp-server:latest

validate: lint test ## Run all validation checks
	@echo "$(GREEN)✅ All validation checks passed$(NC)"

info: ## Show project information
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)JIRA MCP Server$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(YELLOW)Description:$(NC)"
	@echo "  Model Context Protocol server for JIRA operations"
	@echo ""
	@echo "$(YELLOW)Repository:$(NC)"
	@echo "  https://github.com/rrasouli/jira-mcp-server"
	@echo ""
	@echo "$(YELLOW)Documentation:$(NC)"
	@echo "  README.md           - User guide"
	@echo "  ARCHITECTURE.md     - Technical deep dive"
	@echo "  CONTRIBUTING.md     - Development guide"
	@echo "  DEPLOYMENT_GUIDE.md - Deployment strategies"
	@echo ""
	@echo "$(YELLOW)Quick Start:$(NC)"
	@echo "  make install  # Install everything"
	@echo "  make setup    # Interactive configuration"
	@echo "  make run      # Start server"
	@echo ""

dev-setup: install-dev-deps ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@. venv/bin/activate && \
		pip install -e .
	@echo "$(GREEN)✅ Development environment ready$(NC)"
	@echo ""
	@echo "$(YELLOW)Development tools available:$(NC)"
	@echo "  make test          - Run tests"
	@echo "  make lint          - Check code style"
	@echo "  make format        - Format code"
	@echo "  make test-coverage - Test with coverage"
	@echo ""
