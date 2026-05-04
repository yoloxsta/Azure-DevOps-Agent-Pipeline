#!/bin/bash
set -e

echo "========================================"
echo "  Azure DevOps Agent Startup"
echo "========================================"

if [ -z "$AZP_URL" ]; then echo "ERROR: AZP_URL not set"; exit 1; fi
if [ -z "$AZP_TOKEN" ]; then echo "ERROR: AZP_TOKEN not set"; exit 1; fi
if [ -z "$AZP_POOL" ]; then echo "ERROR: AZP_POOL not set"; exit 1; fi

if [ -z "$AZP_AGENT_NAME" ]; then
    export AZP_AGENT_NAME=$(hostname)
fi

echo "URL: $AZP_URL"
echo "Pool: $AZP_POOL"
echo "Agent: $AZP_AGENT_NAME"

echo "Checking agent configuration..."

if [ -f .agent ]; then
    echo "Agent already configured. Skipping configuration."
else
    echo "Configuring agent..."

    ./config.sh --unattended \
        --url "$AZP_URL" \
        --auth pat \
        --token "$AZP_TOKEN" \
        --pool "$AZP_POOL" \
        --agent "$AZP_AGENT_NAME" \
        --acceptTeeEula \
        --work "_work_docker"
fi

echo "Starting agent..."
exec ./run.sh