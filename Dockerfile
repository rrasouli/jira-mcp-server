FROM python:3.11-slim

# Metadata
LABEL maintainer="rrasouli@redhat.com"
LABEL description="JIRA MCP Server - Model Context Protocol server for JIRA operations"
LABEL version="1.0.0"

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install jira CLI
RUN curl -L https://github.com/ankitpokhrel/jira-cli/releases/download/v1.4.0/jira_1.4.0_linux_x86_64.tar.gz | tar xz && \
    mv bin/jira /usr/local/bin/ && \
    chmod +x /usr/local/bin/jira && \
    rm -rf bin/

# Copy application files
COPY server.py /app/
COPY pyproject.toml /app/

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir mcp

# Make server executable
RUN chmod +x server.py

# Environment variables (override at runtime)
ENV JIRA_URL=""
ENV JIRA_DEFAULT_PROJECT=""

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"

# Run the MCP server
ENTRYPOINT ["python", "server.py"]
