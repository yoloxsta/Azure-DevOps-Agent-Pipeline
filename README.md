## Guide

```
docker run -d --name ado-agent-2 --restart always -e AZP_URL="Your Org Url" -e AZP_TOKEN="Your Token" -e AZP_POOL="azureagent" -e AZP_AGENT_NAME="vm-agent-docker-04" -e AZP_AGENT_DOWNGRADE_DISABLED=true ado-agent
```
