#!/bin/bash

# ==============================================================================
# JIRA MCP Server Setup Script
# ==============================================================================
# Sets up the JIRA MCP server for use with Claude Desktop
# ==============================================================================

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header "JIRA MCP Server Setup"

# Check Python version
print_info "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 not found. Please install Python 3.10 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
print_success "Found Python $PYTHON_VERSION"

# Check for jira CLI
print_info "Checking for JIRA CLI..."
if ! command -v jira &> /dev/null; then
    print_warning "JIRA CLI not found"
    echo ""
    echo "Install with:"
    echo "  brew install ankitpokhrel/jira-cli/jira-cli"
    echo ""
    read -p "Would you like to install it now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew install ankitpokhrel/jira-cli/jira-cli
        print_success "JIRA CLI installed"
    else
        print_error "JIRA CLI is required. Exiting."
        exit 1
    fi
else
    print_success "JIRA CLI is installed"
fi

# Check if jira is configured
print_info "Checking JIRA CLI configuration..."
if ! jira version &> /dev/null; then
    print_warning "JIRA CLI not configured"
    echo ""
    print_info "Running 'jira init' to configure..."
    jira init
    print_success "JIRA CLI configured"
else
    print_success "JIRA CLI is configured"
fi

# Create virtual environment
print_info "Creating Python virtual environment..."
if [ -d "venv" ]; then
    print_info "Virtual environment already exists"
else
    python3 -m venv venv
    print_success "Virtual environment created"
fi

# Activate and install dependencies
print_info "Installing dependencies..."
source venv/bin/activate
pip install --upgrade pip > /dev/null 2>&1
pip install mcp > /dev/null 2>&1
print_success "Dependencies installed"

# Make server executable
chmod +x server.py
print_success "Server is executable"

# Get configuration info
echo ""
print_header "Configuration"

# Get current directory
SERVER_PATH="$(pwd)/server.py"
print_info "Server path: $SERVER_PATH"

# Prompt for default project
echo ""
read -p "Enter your default JIRA project key (e.g., WINC, OCPQE): " DEFAULT_PROJECT

# Prompt for JIRA URL
echo ""
read -p "Enter your JIRA URL [https://issues.myorg.com]: " JIRA_URL
JIRA_URL=${JIRA_URL:-https://issues.myorg.com}

# Create Claude Desktop config
CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"

echo ""
print_info "Claude Desktop configuration:"
echo ""
echo "Add this to: $CLAUDE_CONFIG_FILE"
echo ""
cat << EOF
{
  "mcpServers": {
    "jira": {
      "command": "python",
      "args": ["$SERVER_PATH"],
      "env": {
        "JIRA_URL": "$JIRA_URL",
        "JIRA_DEFAULT_PROJECT": "$DEFAULT_PROJECT"
      }
    }
  }
}
EOF

echo ""
read -p "Would you like to update Claude Desktop config automatically? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create directory if it doesn't exist
    mkdir -p "$CLAUDE_CONFIG_DIR"

    # Check if config file exists
    if [ -f "$CLAUDE_CONFIG_FILE" ]; then
        # Backup existing config
        cp "$CLAUDE_CONFIG_FILE" "$CLAUDE_CONFIG_FILE.backup"
        print_info "Backed up existing config to ${CLAUDE_CONFIG_FILE}.backup"

        # Add jira server to existing config (basic merge)
        print_warning "Please manually merge the JIRA server config into your existing file"
        open "$CLAUDE_CONFIG_DIR"
    else
        # Create new config
        cat > "$CLAUDE_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "jira": {
      "command": "python",
      "args": ["$SERVER_PATH"],
      "env": {
        "JIRA_URL": "$JIRA_URL",
        "JIRA_DEFAULT_PROJECT": "$DEFAULT_PROJECT"
      }
    }
  }
}
EOF
        print_success "Claude Desktop config created"
    fi
fi

echo ""
print_header "Setup Complete!"
echo ""
print_success "JIRA MCP Server is ready to use"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Desktop"
echo "  2. Ask Claude: 'Create a story in $DEFAULT_PROJECT called Test Story'"
echo "  3. Claude will use the JIRA MCP server to create the issue"
echo ""
echo "Available commands:"
echo "  - Create issues (Stories, Tasks, Bugs)"
echo "  - Search issues with JQL"
echo "  - Link issues"
echo "  - Transition issues (Close, In Progress, etc.)"
echo "  - Add labels"
echo "  - View issue details"
echo "  - Batch close issues"
echo ""
echo "For more examples, see README.md"
echo ""
