# Azure DevOps Self-Hosted Agent

A Docker-based self-hosted agent for Azure DevOps pipelines.

## Quick Start

```bash
docker run -d \
  --name ado-agent-2 \
  --restart always \
  -e AZP_URL="Your Org Url" \
  -e AZP_TOKEN="Your Token" \
  -e AZP_POOL="azureagent" \
  -e AZP_AGENT_NAME="vm-agent-docker-04" \
  -e AZP_AGENT_DOWNGRADE_DISABLED=true \
  ado-agent
```

## Architecture Overview

| Concept | Analogy |
|---------|---------|
| Dockerfile | Recipe |
| Image | Cooked meal |
| Container | Someone eating the meal |

---

## Part 1 — Dockerfile (Build-Time)

The Dockerfile defines how your agent image is built.

### Step 1 — Base Image

```dockerfile
FROM ubuntu:22.04
```

Start from a clean Linux OS.

### Step 2 — Environment Variables

```dockerfile
ENV AZP_URL=""
ENV AZP_TOKEN=""
ENV AZP_POOL=""
ENV AZP_AGENT_NAME=""
```

These are placeholders that will be filled at runtime (in AKS), not during build.

### Step 3 — Install Base Tools

```dockerfile
apt-get install ...
```

Installs essential tools your pipeline might use:

| Tool | Purpose |
|------|---------|
| `git` | Clone repositories |
| `curl` | Download files |
| `jq` | Parse JSON |
| `sudo` | Permission management |
| `ping` | Network debugging |

### Step 4 — Install Azure CLI + kubectl

```dockerfile
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az aks install-cli
```

Enables the agent to:
- Run `az` commands
- Deploy to AKS
- Run `az acr build`

### Step 5 — Install Node.js

```dockerfile
apt-get install -y nodejs
```

Required because:
- Many Azure DevOps tasks use Node internally
- Frontend builds may require it

### Step 6 — Create User (IMPORTANT)

```dockerfile
useradd -m -s /bin/bash azureuser
```

Creates a safe non-root user to run the agent.

### Step 7 — Agent Installation

```dockerfile
WORKDIR /home/azureuser/agent

curl ... vsts-agent-linux-x64-4.273.0.tar.gz
tar xzf agent.tar.gz
```

Downloads and extracts the Azure DevOps agent software, which provides:
- `config.sh` — Configure agent
- `run.sh` — Run agent

### Step 8 — Fix Permissions (CRITICAL)

```dockerfile
RUN chown -R azureuser:azureuser /home/azureuser
```

**Why?** Files were created by root, but the agent runs as `azureuser`. Without this, you'll get permission denied errors.

### Step 9 — Copy Startup Script

```dockerfile
COPY start.sh ./
```

Copies the startup script into the image.

### Step 10 — Make Script Executable

```dockerfile
RUN chmod +x start.sh
```

### Step 11 — Switch User

```dockerfile
USER azureuser
```

Everything from now on runs as non-root user.

### Step 12 — Container Entrypoint

```dockerfile
ENTRYPOINT ["./start.sh"]
```

When the container starts, `start.sh` runs automatically.

---

## Part 2 — start.sh (Runtime)

This is what happens when the container starts in AKS.

### Step 1 — Fail Fast

```bash
set -e
```

If any command fails, stop immediately.

### Step 2 — Print Info

```bash
echo "Azure DevOps Agent Startup"
```

Logs startup message.

### Step 3 — Validate Required Inputs

```bash
if [ -z "$AZP_URL" ]; then error
```

These must be provided by Kubernetes:

| Variable | Meaning |
|----------|---------|
| `AZP_URL` | Your Azure DevOps organization |
| `AZP_TOKEN` | PAT token |
| `AZP_POOL` | Agent pool |

### Step 4 — Set Agent Name

```bash
AZP_AGENT_NAME=$(hostname)
```

Each pod gets a unique name.

### Step 5 — Check if Already Configured

```bash
if [ -f .agent ]
```

The `.agent` file indicates the agent was already registered.

### Step 6 — Configure Agent (Only Once)

```bash
./config.sh --unattended ...
```

Connects the container to Azure DevOps:
- Registers the agent
- Assigns to pool
- Authenticates with PAT

### Step 7 — Start Agent

```bash
exec ./run.sh
```

The agent now:
- Connects to Azure DevOps
- Waits for jobs
