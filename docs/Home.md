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
- [Semaphore](Semaphore.md)
- [DockScope](DockScope.md)
- [Ansible Playbooks](AnsiblePlaybooks.md)
- [GitLab CI/CD](GitLab-CICD.md)
- [Custom CI Runner Images](CI-Custom-Images.md)
- [Voting App — Mono-Repo](Voting-App-Monorepo.md)
- [Elastic Stack (ELK) — Lab](ElasticStack.md)

## At a glance

| | |
|---|---|
| **Host** | Ubuntu Server |
| **Orchestration** | Docker Compose, one stack per service |
| **Management** | Portainer, **DockScope** (3D visual dashboard) |
| **Monitoring** | Prometheus + Grafana + cAdvisor + node-exporter + **Loki + Alloy** (centralized logs) |
| **Network** | Pi-hole (DNS filtering), Samba (file sharing), nginx (proxy managing) |
| **Automation**     | n8n + **Semaphore** (Ansible Web UI) + **Ansible** (update playbooks) || **Media** | Plex + Sonarr/Radarr/Prowlarr + qBittorrent |
| **Disk health** | Hard Disk Sentinel |
| **AI Agent** | OpenHands + Ollama |
| **CI/CD** | Self-hosted **GitLab** (Omnibus) + Docker-executor **Runner** |

This is a running system, not a demo — screenshots throughout this wiki are from the live dashboards.

Not everything in this repo runs permanently — see [Elastic Stack (ELK) — Lab](ElasticStack.md) for a compose stack kept as a reference from a one-off learning exercise, not part of the always-on services above.
