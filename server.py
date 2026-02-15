#!/usr/bin/env python3
"""
JIRA MCP Server - Generic JIRA operations via Model Context Protocol

Provides JIRA operations (create, edit, link, transition issues) to AI assistants
via the Model Context Protocol.

Usage:
    python server.py

Environment Variables:
    JIRA_URL          - JIRA instance URL (e.g., https://issues.myorg.com)
    JIRA_API_TOKEN    - JIRA API token or password
    JIRA_EMAIL        - JIRA user email
    JIRA_DEFAULT_PROJECT - Default project key (optional)
"""

import os
import sys
import subprocess
import json
from typing import Optional
from mcp.server.fastmcp import FastMCP

# Initialize FastMCP server
mcp = FastMCP("jira-mcp-server")

# Configuration from environment
JIRA_URL = os.getenv("JIRA_URL", "https://issues.myorg.com")
JIRA_DEFAULT_PROJECT = os.getenv("JIRA_DEFAULT_PROJECT", "")

def run_jira_command(args: list[str], check_output: bool = True) -> dict:
    """
    Run jira CLI command and return result.

    Args:
        args: Command arguments to pass to jira CLI
        check_output: If True, return stdout; if False, return success status

    Returns:
        Dictionary with 'success', 'output', and 'error' keys
    """
    try:
        result = subprocess.run(
            ["jira"] + args,
            capture_output=True,
            text=True,
            timeout=30
        )

        return {
            "success": result.returncode == 0,
            "output": result.stdout.strip(),
            "error": result.stderr.strip() if result.returncode != 0 else None
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "output": None,
            "error": "Command timed out after 30 seconds"
        }
    except FileNotFoundError:
        return {
            "success": False,
            "output": None,
            "error": "jira CLI not found. Install with: brew install ankitpokhrel/jira-cli/jira-cli"
        }
    except Exception as e:
        return {
            "success": False,
            "output": None,
            "error": f"Unexpected error: {str(e)}"
        }

@mcp.tool()
def create_issue(
    summary: str,
    issue_type: str,
    project: Optional[str] = None,
    description: Optional[str] = None,
    labels: Optional[str] = None
) -> str:
    """
    Create a new JIRA issue (Story, Task, Bug, etc.).

    Args:
        summary: Issue title/summary
        issue_type: Type of issue (Story, Task, Bug, Epic, Sub-task)
        project: Project key (e.g., MYTEAM, OCPQE). Uses JIRA_DEFAULT_PROJECT if not specified
        description: Issue description (optional)
        labels: Comma-separated labels (e.g., "windows,winc,runtimeclass")

    Returns:
        JSON string with issue key and URL

    Example:
        create_issue("Add RuntimeClass support", "Story", "MYTEAM", "Implement RuntimeClass...", "windows,winc")
    """
    proj = project or JIRA_DEFAULT_PROJECT
    if not proj:
        return json.dumps({"error": "Project required. Set JIRA_DEFAULT_PROJECT or pass project parameter"})

    # Create issue
    args = [
        "issue", "create",
        "-p", proj,
        "-t", issue_type,
        "-s", summary,
        "--no-input"
    ]

    result = run_jira_command(args)

    if not result["success"]:
        return json.dumps({"error": result["error"], "output": result["output"]})

    # Extract issue key from output
    import re
    match = re.search(r'([A-Z]+-\d+)', result["output"])
    if not match:
        return json.dumps({"error": "Could not extract issue key from output", "output": result["output"]})

    issue_key = match.group(1)

    # Add description if provided
    if description:
        desc_result = run_jira_command([
            "issue", "edit", issue_key,
            "-b", description,
            "--no-input"
        ])
        if not desc_result["success"]:
            return json.dumps({
                "issue_key": issue_key,
                "url": f"{JIRA_URL}/browse/{issue_key}",
                "warning": f"Issue created but description failed: {desc_result['error']}"
            })

    # Add labels if provided
    if labels:
        for label in labels.split(","):
            label = label.strip()
            run_jira_command([
                "issue", "edit", issue_key,
                "-l", label,
                "--no-input"
            ])

    return json.dumps({
        "issue_key": issue_key,
        "url": f"{JIRA_URL}/browse/{issue_key}",
        "success": True
    })

@mcp.tool()
def add_labels(issue_key: str, labels: str) -> str:
    """
    Add labels to an existing JIRA issue.

    Args:
        issue_key: Issue key (e.g., MYTEAM-1234)
        labels: Comma-separated labels (e.g., "windows,winc,runtimeclass")

    Returns:
        JSON string with success status

    Example:
        add_labels("MYTEAM-1234", "windows,winc,test")
    """
    results = []
    for label in labels.split(","):
        label = label.strip()
        result = run_jira_command([
            "issue", "edit", issue_key,
            "-l", label,
            "--no-input"
        ])
        results.append({
            "label": label,
            "success": result["success"],
            "error": result["error"] if not result["success"] else None
        })

    return json.dumps({
        "issue_key": issue_key,
        "results": results,
        "url": f"{JIRA_URL}/browse/{issue_key}"
    })

@mcp.tool()
def link_issues(
    inward_issue: str,
    outward_issue: str,
    link_type: str
) -> str:
    """
    Link two JIRA issues together.

    Args:
        inward_issue: First issue key (e.g., MYTEAM-1234)
        outward_issue: Second issue key (e.g., MYTEAM-1235)
        link_type: Link type (blocks, Related, Duplicate, Depend)

    Returns:
        JSON string with success status

    Example:
        link_issues("MYTEAM-1234", "MYTEAM-1235", "blocks")  # 1235 blocks 1234
    """
    result = run_jira_command([
        "issue", "link",
        inward_issue,
        outward_issue,
        link_type
    ])

    return json.dumps({
        "inward_issue": inward_issue,
        "outward_issue": outward_issue,
        "link_type": link_type,
        "success": result["success"],
        "error": result["error"] if not result["success"] else None
    })

@mcp.tool()
def transition_issue(
    issue_key: str,
    state: str,
    resolution: Optional[str] = None,
    comment: Optional[str] = None
) -> str:
    """
    Transition a JIRA issue to a new state.

    Args:
        issue_key: Issue key (e.g., MYTEAM-1234)
        state: Target state (e.g., "In Progress", "Done", "Closed")
        resolution: Resolution type (e.g., "Done", "Won't Fix", "Duplicate")
        comment: Optional comment to add during transition

    Returns:
        JSON string with success status

    Example:
        transition_issue("MYTEAM-1234", "Closed", "Duplicate")
    """
    args = ["issue", "move", issue_key, state, "--no-input"]

    if resolution:
        args.extend(["-R", resolution])

    if comment:
        args.extend(["--comment", comment])

    result = run_jira_command(args)

    return json.dumps({
        "issue_key": issue_key,
        "state": state,
        "resolution": resolution,
        "success": result["success"],
        "error": result["error"] if not result["success"] else None,
        "url": f"{JIRA_URL}/browse/{issue_key}"
    })

@mcp.tool()
def search_issues(
    jql: str,
    max_results: int = 50
) -> str:
    """
    Search for JIRA issues using JQL (JIRA Query Language).

    Args:
        jql: JQL query string (e.g., "project = MYTEAM AND status = Open")
        max_results: Maximum number of results to return (default: 50)

    Returns:
        JSON string with list of matching issues

    Example:
        search_issues("project = MYTEAM AND labels = windows", 10)
    """
    result = run_jira_command([
        "issue", "list",
        "--jql", jql,
        "--plain",
        "--columns", "KEY,SUMMARY,STATUS,ASSIGNEE",
        "--no-headers"
    ])

    if not result["success"]:
        return json.dumps({"error": result["error"]})

    issues = []
    for line in result["output"].split("\n")[:max_results]:
        if line.strip():
            parts = line.split("\t")
            if len(parts) >= 3:
                issues.append({
                    "key": parts[0].strip(),
                    "summary": parts[1].strip() if len(parts) > 1 else "",
                    "status": parts[2].strip() if len(parts) > 2 else "",
                    "assignee": parts[3].strip() if len(parts) > 3 else "",
                    "url": f"{JIRA_URL}/browse/{parts[0].strip()}"
                })

    return json.dumps({
        "jql": jql,
        "count": len(issues),
        "issues": issues
    })

@mcp.tool()
def view_issue(issue_key: str) -> str:
    """
    Get detailed information about a JIRA issue.

    Args:
        issue_key: Issue key (e.g., MYTEAM-1234)

    Returns:
        JSON string with issue details

    Example:
        view_issue("MYTEAM-1234")
    """
    result = run_jira_command([
        "issue", "view", issue_key,
        "--plain"
    ])

    if not result["success"]:
        return json.dumps({"error": result["error"]})

    return json.dumps({
        "issue_key": issue_key,
        "details": result["output"],
        "url": f"{JIRA_URL}/browse/{issue_key}",
        "success": True
    })

@mcp.tool()
def batch_close_issues(
    issue_keys: str,
    resolution: str = "Duplicate",
    comment: Optional[str] = None
) -> str:
    """
    Close multiple JIRA issues at once.

    Args:
        issue_keys: Comma-separated issue keys (e.g., "MYTEAM-1234,MYTEAM-1235,MYTEAM-1236")
        resolution: Resolution type (default: "Duplicate")
        comment: Optional comment to add to all issues

    Returns:
        JSON string with results for each issue

    Example:
        batch_close_issues("OCPQE-31602,OCPQE-31603", "Duplicate", "Closing as duplicate QE trackers")
    """
    results = []
    keys = [k.strip() for k in issue_keys.split(",")]

    for key in keys:
        result = transition_issue(key, "Closed", resolution, comment)
        results.append(json.loads(result))

    return json.dumps({
        "total": len(keys),
        "results": results
    })

if __name__ == "__main__":
    # Run the MCP server
    mcp.run()
