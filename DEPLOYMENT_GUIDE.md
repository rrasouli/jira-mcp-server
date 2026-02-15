# JIRA MCP Server - Deployment Guide for Organizations

This guide explains how to deploy the JIRA MCP server for your entire organization.

## What You Have

-  **Generic MCP Server**: Works with any JIRA instance
-  **Project-agnostic**: Can be used with any JIRA project
-  **Standard MCP protocol**: Works with Claude Desktop and other MCP clients

## Deployment Options

### Option 1: Internal Git Repository (Recommended)

**Best for:** Organizations using internal GitHub/GitLab

#### Steps:

1. **Create Internal Repository**

```bash
cd ~/jira-mcp-server

# Initialize git
git init
git add .
git commit -m "Initial JIRA MCP server

Provides JIRA operations via Model Context Protocol:
- Create issues (Stories, Tasks, Bugs)
- Search issues with JQL
- Link issues
- Transition issues
- Add labels
- Batch operations"

# Add remote (use your organization's Git server)
git remote add origin https://github.com/your-org/jira-mcp-server.git
git push -u origin main
```

2. **Document for Teams**

Add to your organization's wiki/docs:

```markdown
# Using JIRA MCP Server with Claude

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/jira-mcp-server.git ~/jira-mcp-server
   ```

2. Run setup:
   ```bash
   cd ~/jira-mcp-server
   ./setup.sh
   ```

3. Restart Claude Desktop

4. Ask Claude: "Create a story in MYTEAM called 'Test Story'"
```

3. **Provide Support**

- Create Slack channel: `#jira-mcp-support`
- Designate team members as maintainers
- Document common issues in README

---

### Option 2: Internal PyPI Server

**Best for:** Organizations with existing Python package infrastructure

#### Steps:

1. **Build Package**

```bash
cd ~/jira-mcp-server
pip install build twine
python -m build
```

2. **Upload to Internal PyPI**

```bash
twine upload --repository-url https://pypi.your-org.com dist/*
```

3. **Teams Install With**

```bash
pip install jira-mcp-server --index-url https://pypi.your-org.com
```

4. **Configure Claude Desktop**

Users add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "jira": {
      "command": "jira-mcp-server"
    }
  }
}
```

---

### Option 3: Shared Network Location

**Best for:** Organizations with shared network drives

#### Steps:

1. **Copy to Shared Location**

```bash
cp -r ~/jira-mcp-server /Volumes/SharedDrive/Tools/jira-mcp-server
```

2. **Teams Reference Shared Path**

In Claude Desktop config:

```json
{
  "mcpServers": {
    "jira": {
      "command": "python",
      "args": ["/Volumes/SharedDrive/Tools/jira-mcp-server/server.py"]
    }
  }
}
```

3. **Centralized Updates**

When you update the server, all users get the new version automatically.

---

### Option 4: Container Image (Advanced)

**Best for:** Organizations using Docker/Kubernetes

#### Steps:

1. **Create Dockerfile**

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY . /app

RUN pip install mcp && \
    apt-get update && \
    apt-get install -y curl && \
    # Install jira CLI
    curl -L https://github.com/ankitpokhrel/jira-cli/releases/download/v1.4.0/jira_1.4.0_linux_x86_64.tar.gz | tar xz && \
    mv bin/jira /usr/local/bin/

ENTRYPOINT ["python", "server.py"]
```

2. **Build and Push**

```bash
docker build -t your-registry.com/jira-mcp-server:1.0.0 .
docker push your-registry.com/jira-mcp-server:1.0.0
```

3. **Run Container**

```bash
docker run -e JIRA_URL=https://issues.myorg.com \
           -e JIRA_DEFAULT_PROJECT=MYTEAM \
           your-registry.com/jira-mcp-server:1.0.0
```

---

## Security Considerations

### 1. Credential Management

**Problem:** Users need JIRA credentials to use the server

**Solutions:**

- **Option A:** Users configure their own JIRA CLI (`jira init`)
- **Option B:** Use service account with limited permissions
- **Option C:** Integrate with organization SSO/OAuth

**Recommendation:** Option A (user credentials via JIRA CLI)

### 2. Access Control

**Problem:** Server runs with user's JIRA permissions

**Solutions:**

- Educate users about what the server can do
- Implement audit logging
- Create read-only version for sensitive projects

### 3. API Token Security

**Never:**
-  Commit API tokens to git
-  Store tokens in code
-  Share tokens between users

**Always:**
-  Use environment variables
-  Use JIRA CLI's secure credential storage
-  Rotate tokens regularly

---

## Customization for Your Organization

### 1. Add Organization-Specific Tools

Edit `server.py` to add custom tools:

```python
@mcp.tool()
def create_release_tracker(
    release_version: str,
    target_date: str
) -> str:
    """
    Create a standardized release tracker issue.

    Your organization's specific template for release tracking.
    """
    # Create epic
    epic = create_issue(
        f"Release {release_version}",
        "Epic",
        "RELEASES",
        f"Track release {release_version} deliverables"
    )

    # Create standard sub-tasks
    tasks = [
        "Code freeze",
        "QE testing",
        "Documentation review",
        "Release notes"
    ]

    # Link tasks to epic
    # ...

    return json.dumps({"epic": epic, "tasks": tasks})
```

### 2. Add Project Templates

```python
PROJECT_TEMPLATES = {
    "MYTEAM": {
        "default_labels": ["windows", "winc"],
        "required_fields": ["Environment", "Test Coverage"]
    },
    "OCPQE": {
        "default_labels": ["qe", "testing"],
        "required_fields": ["Test Plan"]
    }
}
```

### 3. Add Validation Rules

```python
def validate_issue_creation(project, issue_type, summary):
    """Validate issue creation follows org standards"""
    if issue_type == "Story" and not summary.startswith("[Feature]"):
        raise ValueError("Story summaries must start with [Feature]")

    if project == "SECURITY" and issue_type == "Bug":
        raise ValueError("Use 'Vulnerability' type for security project")
```

---

## Monitoring and Metrics

### 1. Add Logging

```python
import logging

logging.basicConfig(
    filename="/var/log/jira-mcp-server.log",
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

@mcp.tool()
def create_issue(...):
    logging.info(f"Creating {issue_type} in {project}: {summary}")
    # ... rest of function
```

### 2. Track Usage

```python
import json
from datetime import datetime

def track_usage(tool_name, user, project):
    """Track MCP tool usage"""
    with open("/var/log/mcp-usage.jsonl", "a") as f:
        f.write(json.dumps({
            "timestamp": datetime.now().isoformat(),
            "tool": tool_name,
            "user": user,
            "project": project
        }) + "\n")
```

### 3. Error Reporting

```python
def report_error(error, context):
    """Send errors to monitoring system"""
    # Send to Sentry, Datadog, etc.
    pass
```

---

## Maintenance

### 1. Regular Updates

```bash
# Pull latest changes
cd ~/jira-mcp-server
git pull origin main

# Update dependencies
source venv/bin/activate
pip install --upgrade mcp

# Restart Claude Desktop
```

### 2. Version Management

Use semantic versioning:
- **Major (1.0.0 → 2.0.0):** Breaking changes
- **Minor (1.0.0 → 1.1.0):** New features
- **Patch (1.0.0 → 1.0.1):** Bug fixes

### 3. Deprecation Policy

When removing/changing tools:
1. Mark as deprecated in v1.x
2. Keep for 2 minor versions
3. Remove in v2.0.0

---

## Testing

### 1. Unit Tests

```python
import pytest
from server import create_issue

def test_create_issue():
    result = create_issue(
        "Test Issue",
        "Task",
        "TEST",
        "Description",
        "test,automation"
    )
    assert "issue_key" in result
    assert "TEST-" in result["issue_key"]
```

### 2. Integration Tests

```bash
# Test with real JIRA instance (use test project)
pytest tests/integration/ --jira-project=TEST
```

---

## Support

### 1. Documentation

Maintain wiki pages:
- Installation guide
- Common use cases
- Troubleshooting
- FAQ

### 2. Training

Provide training sessions:
- "Getting Started with JIRA MCP Server"
- "Advanced JQL Queries with Claude"
- "Batch Operations and Automation"

### 3. Support Channels

- Slack: `#jira-mcp-support`
- Email: jira-mcp-support@your-org.com
- Office hours: Tuesdays 2-3pm

---

## Success Metrics

Track:
- Number of active users
- Issues created via MCP vs manual
- Time saved (estimated)
- User satisfaction (surveys)

Example metrics dashboard:
- Daily active users: 45
- Issues created this month: 234
- Average time saved per issue: 2 minutes
- User satisfaction: 4.5/5

---

## Next Steps

1.  Choose deployment option
2.  Customize for your organization
3.  Set up monitoring
4.  Create documentation
5.  Pilot with small team
6.  Gather feedback
7.  Roll out to organization
8.  Maintain and improve

---

## Contact

For questions about this deployment guide:
- Technical: your-team@example.com
- Process: project-management@example.com
