# Homelab Wiki

Documentation for a self-hosted homelab running entirely on Docker Compose. This wiki covers the *why* behind each service, how they're configured, and what I learned running them — the repo itself has the raw `docker-compose.yml` files.

## Contents

- [Architecture and Hardware](Architecture-and-Hardware.md)
- [Monitoring Stack](Monitoring-Stack.md)
- [Network Services](Network-Services.md)
- [Media Automation](Media-Automation.md)
- [Workflow Automation](Workflow-Automation.md)
- [Storage Health](Storage-Health.md)
- [Lessons Learned](Lessons-Learned.md)
- [AI Coding Agent](AI-Agent.md)
- [Reverse Proxy](Reverse-Proxy.md)

## At a glance

| | |
|---|---|
| **Host** | Ubuntu Server |
| **Orchestration** | Docker Compose, one stack per service |
| **Management** | Portainer |
| **Monitoring** | Prometheus + Grafana + cAdvisor + node-exporter |
| **Network** | Pi-hole (DNS filtering), Samba (file sharing), nginx (proxy managing) |
| **Automation** | n8n |
| **Media** | Plex + Sonarr/Radarr/Prowlarr + qBittorrent |
| **Disk health** | Hard Disk Sentinel |
| **AI Agent** | OpenHands + Ollama |

This is a running system, not a demo — screenshots throughout this wiki are from the live dashboards.
