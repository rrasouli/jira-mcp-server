# Cursor Integration Guide

This guide explains how to integrate the **rrasouli/jira-mcp-server** (Python-based) into Cursor editor.

## Overview

Cursor supports MCP (Model Context Protocol) servers through JSON configuration files. You create a `mcp.json` file that tells Cursor how to launch and communicate with the JIRA MCP server. Once configured, the server's tools become available in Cursor's agentic chat.

## Prerequisites

### Required Software

1. **Python 3.10 or higher**
   ```bash
   python3 --version  # Should be 3.10+
   ```

2. **jira-cli** ([ankitpokhrel/jira-cli](https://github.com/ankitpokhrel/jira-cli))
   ```bash
   # macOS
   brew install ankitpokhrel/jira-cli/jira-cli

   # Linux
   curl -L https://github.com/ankitpokhrel/jira-cli/releases/download/v1.4.0/jira_1.4.0_linux_x86_64.tar.gz | tar xz
   sudo mv bin/jira /usr/local/bin/
   ```

3. **JIRA credentials** configured

## Installation Steps

### 1. Clone and Install the Server

```bash
# Clone the repository
git clone https://github.com/rrasouli/jira-mcp-server.git
cd jira-mcp-server

# One-command installation (recommended)
make install

# Follow prompts to:
# - Install prerequisites (Python, jira-cli)
# - Configure JIRA credentials
# - Set up virtual environment
```

### 2. Configure JIRA CLI Authentication

If not done during `make install`, run:

```bash
jira init
```

Provide:
- **JIRA Instance URL**: `https://your-company.atlassian.net`
- **Authentication method**: Personal Access Token (recommended) or Basic Auth
- **Your credentials**: API token from [Atlassian Security](https://id.atlassian.com/manage-profile/security/api-tokens)

Credentials are securely stored in your OS keychain (macOS Keychain, Linux Secret Service).

### 3. Get Absolute Paths

You need two absolute paths for configuration:

**Path to Python executable:**
```bash
# If using virtual environment (recommended)
cd ~/jira-mcp-server
source venv/bin/activate
which python

# Example output: /Users/username/jira-mcp-server/venv/bin/python
```

**Path to server.py:**
```bash
cd ~/jira-mcp-server
echo "$(pwd)/server.py"

# Example output: /Users/username/jira-mcp-server/server.py
```

Copy both paths for the next step.

## Cursor Configuration

Cursor supports MCP servers through configuration files at two levels:

### Option 1: Global Configuration (All Projects)

Create or edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "jira": {
      "command": "python3",
      "args": [
        "/Users/YOUR_USERNAME/jira-mcp-server/server.py"
      ],
      "env": {
        "JIRA_URL": "https://your-company.atlassian.net",
        "JIRA_DEFAULT_PROJECT": "MYTEAM"
      }
    }
  }
}
```

**Using virtual environment Python (recommended):**

```json
{
  "mcpServers": {
    "jira": {
      "command": "/Users/YOUR_USERNAME/jira-mcp-server/venv/bin/python",
      "args": [
        "/Users/YOUR_USERNAME/jira-mcp-server/server.py"
      ],
      "env": {
        "JIRA_URL": "https://your-company.atlassian.net",
        "JIRA_DEFAULT_PROJECT": "MYTEAM"
      }
    }
  }
}
```

### Option 2: Project-Specific Configuration

Create `.cursor/mcp.json` in your project root with the same format as above.

**Note**: Project-level servers are only available in that specific project.

### Creating the Configuration File

```bash
# Create global config directory if it doesn't exist
mkdir -p ~/.cursor

# Create/edit the config file
nano ~/.cursor/mcp.json
# Or use your preferred editor: code, vim, etc.
```

Paste the configuration from Option 1 or Option 2 above, replacing:
- `YOUR_USERNAME` with your actual username
- `your-company.atlassian.net` with your JIRA URL
- `MYTEAM` with your default project key

### Verify Configuration

1. **Restart Cursor** after editing the configuration file
2. **Open Cursor Settings** (Cmd + , / Ctrl + ,)
3. **Navigate to**: MCP Servers (or search for "MCP" in settings)
4. **Check**: "jira" server should appear with a list of available tools
5. **View Logs**: Click on the server to see connection status and debug info

## Environment Variables

| Variable | Required | Example | Description |
|----------|----------|---------|-------------|
| `JIRA_URL` | Yes | `https://issues.myorg.com` | Your JIRA instance URL |
| `JIRA_DEFAULT_PROJECT` | No | `MYTEAM` | Default project key for issue creation |

**Note**: Authentication credentials are NOT in env vars - they're managed by jira-cli in your OS keychain.

## Validation & Testing

### Test the MCP Server

Open Cursor Composer (Cmd + I / Ctrl + I) and try:

```
"Create a test story in MYTEAM called 'MCP Integration Test'"
```

or

```
"Search for open issues in MYTEAM project"
```

or

```
"Show me issue MYTEAM-1234"
```

### Troubleshooting

#### Red Status Indicator

**Check logs in Cursor MCP settings:**

1. Common issues:
   - Python not found: Use full path to Python executable
   - server.py not found: Verify absolute path
   - jira-cli not configured: Run `jira init` first
   - Permission denied: Run `chmod +x server.py`

2. Test manually in terminal:
   ```bash
   cd ~/jira-mcp-server
   python server.py
   # Should start and wait for MCP protocol messages
   # Press Ctrl+C to stop
   ```

#### "JIRA CLI not configured"

```bash
# Initialize JIRA CLI
jira init

# Test it works
jira issue list -p MYTEAM
```

#### Connection Timeout

- Verify JIRA_URL is correct (no trailing slash)
- Check network/VPN if using internal JIRA
- Verify jira-cli works: `jira issue list`

## Available Tools

Once integrated, you can use these JIRA operations through Cursor:

1. **create_issue** - Create Story, Task, Bug, Epic, Sub-task
2. **search_issues** - JQL search for issues
3. **link_issues** - Link issues (blocks, relates, duplicates)
4. **transition_issue** - Move issues through workflow
5. **add_labels** - Add labels to issues
6. **view_issue** - Get detailed issue information
7. **batch_close_issues** - Close multiple issues at once

## Differences from Node.js JIRA MCP Servers

This is a **Python-based** MCP server with different architecture:

| Feature | This Server (Python) | Other Servers (Node.js) |
|---------|---------------------|------------------------|
| Language | Python + FastMCP | Node.js + TypeScript |
| Entry Point | `server.py` | `dist/index.js` |
| Build Required | No | Yes (`npm run build`) |
| Authentication | jira-cli (OS keychain) | Direct API token |
| Credentials | Managed by jira-cli | In environment variables |
| Installation | `make install` | `npm install` |

## Alternative: Use Claude Desktop or Claude Code

If Cursor doesn't support Python-based MCP servers yet:

1. **Claude Desktop** - GUI application with MCP support
2. **Claude Code** - CLI tool with MCP support

See [README.md](README.md) for configuration instructions.

## Support

- **GitHub Issues**: https://github.com/rrasouli/jira-mcp-server/issues
- **JIRA CLI Docs**: https://github.com/ankitpokhrel/jira-cli
- **MCP Protocol**: https://modelcontextprotocol.io

## How Cursor MCP Integration Works

Cursor reads MCP server configurations from JSON files:

1. **Global scope**: `~/.cursor/mcp.json` - Available across all projects
2. **Project scope**: `.cursor/mcp.json` in project root - Only for that project

The configuration specifies:
- **command**: Path to the Python executable
- **args**: Arguments (path to server.py)
- **env**: Environment variables (JIRA_URL, JIRA_DEFAULT_PROJECT)

When you use Cursor's chat, it launches the MCP server as a subprocess and communicates via stdio using the MCP protocol. The server exposes tools (create_issue, search_issues, etc.) that Cursor's AI can call to interact with JIRA.

## Contributing

If you successfully integrate with Cursor or find issues, please:
1. Open an issue describing your setup
2. Share configuration that worked
3. Help improve this guide
