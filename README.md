## Guide

```
docker run -d --name ado-agent-2 --restart always -e AZP_URL="Your Org Url" -e AZP_TOKEN="Your Token" -e AZP_POOL="azureagent" -e AZP_AGENT_NAME="vm-agent-docker-04" -e AZP_AGENT_DOWNGRADE_DISABLED=true ado-agent
```
###

```
PART 1 — Dockerfile (build-time)

 The Dockerfile defines how your agent image is built

Think:

Dockerfile = recipe
Image = cooked meal
Container = someone eating the meal
🔹 Step 1 — Base image
FROM ubuntu:22.04

 Start from a clean Linux OS

🔹 Step 2 — Environment variables
ENV AZP_URL=""
ENV AZP_TOKEN=""
ENV AZP_POOL=""
ENV AZP_AGENT_NAME=""

 These are placeholders

They will be filled later at runtime (in AKS)
NOT during build

🔹 Step 3 — Install base tools
apt-get install ...

You install:

git → clone repos
curl → download stuff
jq → parse JSON
sudo → permissions
ping → debug network

 These are tools your pipeline might use

🔹 Step 4 — Install Azure CLI + kubectl
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az aks install-cli

 This gives your agent power to:

run az commands
deploy to AKS
run az acr build
🔹 Step 5 — Install Node.js
apt-get install -y nodejs

 Needed because:

many Azure DevOps tasks use Node internally
frontend builds may require it
🔹 Step 6 — Create user (VERY IMPORTANT)
useradd -m -s /bin/bash azureuser

 Instead of running as root, you create:

safe user = azureuser
🔹 Step 7 — Agent installation
WORKDIR /home/azureuser/agent

 This is the working directory

curl ... vsts-agent-linux-x64-4.273.0.tar.gz
tar xzf agent.tar.gz

 You download and extract:

 Azure DevOps agent software

This gives you:

config.sh  → configure agent
run.sh     → run agent
🔹 Step 8 — Fix permissions (CRITICAL)
RUN chown -R azureuser:azureuser /home/azureuser

 Why?

Because:

files were created by root
but agent runs as azureuser

Without this:

 permission denied errors
🔹 Step 9 — Copy startup script
COPY start.sh ./

 This puts your script inside the image

🔹 Step 10 — Make script executable
RUN chmod +x start.sh
🔹 Step 11 — Switch user
USER azureuser

 From now on:

everything runs as non-root user
🔹 Step 12 — Container entrypoint
ENTRYPOINT ["./start.sh"]

 When container starts:

start.sh runs automatically
-> PART 2 — start.sh (runtime)

 This is what happens when container starts in AKS

🔹 Step 1 — Fail fast
set -e

 If any command fails → stop immediately

🔹 Step 2 — Print info
echo "Azure DevOps Agent Startup"

Just logs

🔹 Step 3 — Validate required inputs
if [ -z "$AZP_URL" ]; then error

 These must be provided by Kubernetes:

Variable	Meaning
AZP_URL	your Azure DevOps org
AZP_TOKEN	PAT token
AZP_POOL	agent pool
🔹 Step 4 — Set agent name
AZP_AGENT_NAME=$(hostname)

 Each pod gets unique name

🔹 Step 5 — Check if already configured
if [ -f .agent ]

 .agent file means:

Agent already registered before
🔹 Step 6 — Configure agent (only once)
./config.sh --unattended ...

This connects your container to Azure DevOps.

It does:
registers agent
assigns to pool
authenticates with PAT
🔹 Step 7 — Start agent
exec ./run.sh

 Now the agent:

connects to Azure DevOps
waits for jobs
```