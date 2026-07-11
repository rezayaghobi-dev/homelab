# Homelab Wiki

Documentation for a self-hosted homelab running entirely on Docker Compose. This wiki covers the *why* behind each service, how they're configured, and what I learned running them — the repo itself has the raw `docker-compose.yml` files.

## Contents

- [[Architecture and Hardware]]
- [[Monitoring Stack]]
- [[Network Services]]
- [[Media Automation]]
- [[Workflow Automation]]
- [[Storage Health]]
- [[Lessons Learned]]

## At a glance

| | |
|---|---|
| **Host** | Ubuntu Server |
| **Orchestration** | Docker Compose, one stack per service |
| **Management** | Portainer |
| **Monitoring** | Prometheus + Grafana + cAdvisor + node-exporter |
| **Network** | Pi-hole (DNS filtering), Samba (file sharing) |
| **Automation** | n8n |
| **Media** | Plex + Sonarr/Radarr/Prowlarr + qBittorrent |
| **Disk health** | Hard Disk Sentinel |

This is a running system, not a demo — screenshots throughout this wiki are from the live dashboards.
