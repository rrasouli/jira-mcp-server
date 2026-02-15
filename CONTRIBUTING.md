# Contributing to JIRA MCP Server

Thank you for your interest in contributing to the JIRA MCP Server! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Adding New Tools](#adding-new-tools)
- [Documentation](#documentation)

---

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Focus on constructive feedback
- Prioritize project goals over personal preferences
- Maintain professional communication

### Unacceptable Behavior

- Harassment or discriminatory language
- Personal attacks or trolling
- Publishing private information
- Other unprofessional conduct

---

## Getting Started

### Prerequisites

- Python 3.10 or higher
- Git for version control
- JIRA CLI installed and configured
- Access to a JIRA test instance (recommended)

### Finding Issues to Work On

1. Check the issue tracker for `good first issue` labels
2. Look for `help wanted` tags
3. Review the roadmap for upcoming features
4. Propose new features via GitHub Discussions

---

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/jira-mcp-server.git
cd jira-mcp-server

# Add upstream remote
git remote add upstream https://github.com/your-org/jira-mcp-server.git
```

### 2. Create Development Environment

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install --upgrade pip
pip install mcp
pip install pytest pytest-cov  # Testing dependencies
pip install black flake8 mypy  # Development tools
```

### 3. Configure Development JIRA Instance

```bash
# Configure jira-cli to point to test instance
jira init

# Use test credentials
# JIRA URL: https://jira-test.your-company.com
# Project: TEST
```

### 4. Verify Setup

```bash
# Run the server
python server.py

# Should start without errors
# Press Ctrl+C to stop
```

---

## Making Changes

### Branch Naming Convention

Use descriptive branch names following this pattern:

```
feature/add-bulk-edit-tool
bugfix/fix-timeout-handling
docs/update-installation-guide
refactor/simplify-error-handling
```

### Workflow

```bash
# 1. Create a new branch
git checkout -b feature/your-feature-name

# 2. Make your changes
# Edit files...

# 3. Test your changes
pytest tests/

# 4. Format code
black server.py
flake8 server.py

# 5. Commit changes
git add .
git commit -m "Add feature: description of changes"

# 6. Push to your fork
git push origin feature/your-feature-name

# 7. Create Pull Request on GitHub
```

---

## Testing

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=server --cov-report=html

# Run specific test file
pytest tests/test_create_issue.py

# Run specific test
pytest tests/test_create_issue.py::test_create_story
```

### Writing Tests

Create test files in the `tests/` directory:

```python
# tests/test_your_feature.py
import pytest
from server import create_issue

def test_create_issue_success():
    """Test successful issue creation"""
    result = create_issue(
        summary="Test Issue",
        issue_type="Task",
        project="TEST"
    )

    assert result["success"] is True
    assert "issue_key" in result
    assert "TEST-" in result["issue_key"]

def test_create_issue_missing_project():
    """Test issue creation without project"""
    result = create_issue(
        summary="Test Issue",
        issue_type="Task"
    )

    assert "error" in result
```

### Test Coverage Requirements

- All new features must have tests
- Maintain minimum 80% code coverage
- Include both success and failure scenarios
- Test edge cases

---

## Pull Request Process

### Before Submitting

1. **Update Documentation**
   - Update README.md if adding features
   - Add docstrings to new functions
   - Update CHANGELOG.md

2. **Run All Checks**
   ```bash
   # Format code
   black server.py

   # Check style
   flake8 server.py

   # Type checking
   mypy server.py

   # Run tests
   pytest
   ```

3. **Write Clear Commit Messages**
   ```
   Add batch_edit_issues tool

   - Implements batch editing functionality
   - Supports multiple field updates
   - Includes error handling and rollback
   - Adds comprehensive tests

   Closes #123
   ```

### Pull Request Template

When creating a PR, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Added new tests
- [ ] All tests passing
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No breaking changes (or clearly documented)
```

### Review Process

1. At least one maintainer must approve
2. All CI checks must pass
3. No merge conflicts
4. Documentation complete
5. Tests passing

---

## Coding Standards

### Python Style

Follow [PEP 8](https://pep8.org/) with these specifics:

```python
# Use Black formatter (line length: 88)
# Use type hints
def create_issue(
    summary: str,
    issue_type: str,
    project: Optional[str] = None
) -> str:
    """
    Create a new JIRA issue.

    Args:
        summary: Issue title
        issue_type: Type of issue (Story, Task, Bug)
        project: Project key (optional)

    Returns:
        JSON string with issue details
    """
    pass

# Use descriptive variable names
issue_key = "PLATFORM-1234"  # Good
ik = "PLATFORM-1234"  # Bad

# Keep functions focused and small
def run_jira_command(args: list[str]) -> dict:
    """Single responsibility: execute jira command"""
    # Implementation
    pass
```

### Error Handling

```python
# Always use try/except for external calls
try:
    result = subprocess.run(["jira"] + args, capture_output=True)
except subprocess.TimeoutExpired:
    return {"error": "Command timed out"}
except FileNotFoundError:
    return {"error": "jira CLI not found"}
except Exception as e:
    return {"error": f"Unexpected error: {str(e)}"}

# Return structured error messages
def some_function() -> str:
    if not project:
        return json.dumps({"error": "Project required"})

    # Continue with logic
```

### JSON Response Format

All tools must return JSON strings:

```python
# Success response
return json.dumps({
    "success": True,
    "issue_key": "PLATFORM-1234",
    "url": f"{JIRA_URL}/browse/PLATFORM-1234"
})

# Error response
return json.dumps({
    "error": "Descriptive error message",
    "details": additional_context
})
```

---

## Adding New Tools

### Tool Template

```python
@mcp.tool()
def your_tool_name(
    required_param: str,
    optional_param: Optional[str] = None
) -> str:
    """
    One-line description of what this tool does.

    Detailed explanation of the tool's purpose and behavior.
    Include any important notes or warnings.

    Args:
        required_param: Description of required parameter
        optional_param: Description of optional parameter

    Returns:
        JSON string with result structure

    Example:
        your_tool_name("value1", "value2")
    """
    # 1. Validate inputs
    if not required_param:
        return json.dumps({"error": "required_param cannot be empty"})

    # 2. Build jira CLI command
    args = ["issue", "your-operation"]
    args.extend(["-p", required_param])

    if optional_param:
        args.extend(["--option", optional_param])

    # 3. Execute command
    result = run_jira_command(args)

    # 4. Handle errors
    if not result["success"]:
        return json.dumps({
            "error": result["error"],
            "command": " ".join(args)
        })

    # 5. Parse and return result
    return json.dumps({
        "success": True,
        "data": result["output"]
    })
```

### Tool Guidelines

1. **Single Responsibility**: Each tool should do one thing well
2. **Descriptive Names**: Use verb-noun pattern (create_issue, search_issues)
3. **Comprehensive Docstrings**: Include examples and parameter descriptions
4. **Error Handling**: Always handle and report errors gracefully
5. **Structured Output**: Return JSON with consistent format
6. **Type Hints**: Use Python type hints for all parameters

### Testing New Tools

```python
# tests/test_your_tool.py
def test_your_tool_success():
    """Test successful execution"""
    result = your_tool_name("test-value")
    data = json.loads(result)
    assert data["success"] is True

def test_your_tool_missing_param():
    """Test with missing required parameter"""
    result = your_tool_name("")
    data = json.loads(result)
    assert "error" in data

def test_your_tool_jira_error():
    """Test handling of JIRA API errors"""
    # Mock jira CLI failure
    result = your_tool_name("invalid-project")
    data = json.loads(result)
    assert "error" in data
```

---

## Documentation

### README Updates

When adding features, update:

1. **Features section**: Add bullet point
2. **Available Tools section**: Add full documentation
3. **Usage Examples**: Add real-world example

### Docstring Format

```python
def function_name(param1: str, param2: int) -> str:
    """
    Brief one-line summary.

    Detailed explanation of what the function does.
    Include any important behavior or side effects.

    Args:
        param1: Description of parameter 1
        param2: Description of parameter 2

    Returns:
        Description of return value

    Raises:
        ValueError: When invalid input provided

    Example:
        >>> function_name("test", 123)
        '{"result": "success"}'
    """
```

### CHANGELOG Format

```markdown
## [Version] - YYYY-MM-DD

### Added
- New feature description

### Changed
- Modified behavior description

### Fixed
- Bug fix description

### Deprecated
- Feature being phased out

### Removed
- Removed feature

### Security
- Security improvement
```

---

## Release Process

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **Major (1.0.0 → 2.0.0)**: Breaking changes
- **Minor (1.0.0 → 1.1.0)**: New features, backwards compatible
- **Patch (1.0.0 → 1.0.1)**: Bug fixes, backwards compatible

### Creating a Release

1. Update version in `pyproject.toml`
2. Update CHANGELOG.md
3. Create git tag: `git tag -a v1.1.0 -m "Release v1.1.0"`
4. Push tag: `git push origin v1.1.0`
5. GitHub Actions will build and publish

---

## Questions?

- **Slack**: `#jira-mcp-dev`
- **Email**: mcp-dev@your-company.com
- **Discussions**: Use GitHub Discussions for questions

---

Thank you for contributing to JIRA MCP Server!
