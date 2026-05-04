FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV AZP_URL=""
ENV AZP_TOKEN=""
ENV AZP_POOL=""
ENV AZP_AGENT_NAME=""

# ================================
# Base dependencies
# ================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl jq git git-lfs unzip wget \
    apt-transport-https lsb-release gnupg software-properties-common sudo \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# ================================
# Azure CLI + kubectl
# ================================
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az aks install-cli

# ================================
# Docker CLI (for pipelines)
# ================================
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# ================================
# Node.js (optional build tools)
# ================================
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ================================
# Create user
# ================================
RUN useradd -m -s /bin/bash azureuser \
    && echo "azureuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ================================
# IMPORTANT: Docker group alignment (FIX)
# Host docker group GID = 988
# ================================
RUN groupadd -g 988 docker || true \
    && usermod -aG docker azureuser

# ================================
# Agent setup
# ================================
WORKDIR /home/azureuser/agent

RUN curl -L -o agent.tar.gz \
    "https://download.agent.dev.azure.com/agent/4.273.0/vsts-agent-linux-x64-4.273.0.tar.gz" \
    && tar xzf agent.tar.gz \
    && rm agent.tar.gz

# Ownership fix
RUN chown -R azureuser:azureuser /home/azureuser

# ================================
# Start script
# ================================
USER azureuser
COPY start.sh ./

USER root
RUN chmod +x start.sh

USER azureuser

ENTRYPOINT ["./start.sh"]