# Homelab

A self-hosted homelab running on Docker Compose, built and maintained on an Ubuntu Server. This repo documents the actual infrastructure-as-code behind it — deployment configs only, no runtime data or secrets.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=flat&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu_Server-E95420?style=flat&logo=ubuntu&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)

## Overview

This is a real, running homelab — not a demo. It's deployed on a home Ubuntu server and managed entirely through Docker Compose, with each service isolated in its own folder. Configs here are the actual files running in production, with all secrets, API keys, and runtime state stripped out and replaced with `.env.example` placeholders.

## Services

| Service | Folder | Purpose |
|---|---|---|
| **Monitoring stack** | `monitoring-grafana-promethues-cadvisor-node-exporter/` | Prometheus for metrics collection, Grafana for dashboards, cAdvisor for per-container resource stats, node-exporter for host-level metrics |
| **Pi-hole** | `pihole/` | Network-wide DNS-level ad and tracker blocking |
| **Portainer** | `portainer/` | Web UI for managing and monitoring all Docker containers on the host |
| **n8n** | `n8n/` | Workflow automation engine, backed by Postgres |
| **Samba** | `samba/` | Network file sharing across LAN devices |
| **Filebrowser** | `filebrowser/` | Web-based file manager for the server's storage |
| **Media stack** | `mediastack/` | Plex (media server), Sonarr/Radarr/Prowlarr (media automation and indexing), qBittorrent (download client) |
| **Minecraft** | `minecraft/` | Self-hosted game server |
| **Sentinel** | `sentinel/` | _TODO: describe what this monitors/does_ |
| **smartctl** | `smartctl/` | Disk health monitoring (S.M.A.R.T. data) |

## Repository structure

```
homelab/
├── monitoring-grafana-promethues-cadvisor-node-exporter/
│   └── docker-compose.yml
├── pihole/
│   ├── docker-compose.yml
│   └── .env.example
├── portainer/
│   └── docker-compose.yml
├── n8n/
│   ├── docker-compose.yaml
│   └── .env.example
├── samba/
│   ├── docker-compose.yml
│   └── .env.example
├── filebrowser/
│   └── docker-compose.yml
├── mediastack/
│   ├── plex/docker-compose.yml
│   ├── sonarr/docker-compose.yml
│   ├── radarr/docker-compose.yml
│   ├── prowlarr/docker-compose.yml
│   ├── whisparr/docker-compose.yml
│   └── download-client-qbittorent/docker-compose.yml
├── minecraft/
│   └── docker-compose.yml
├── sentinel/
│   └── docker-compose.yml
├── smartctl/
│   └── docker-compose.yml
└── .gitignore
```

## Running a service

Each folder is a standalone Compose stack:

```bash
cd pihole
cp .env.example .env   # fill in real values
docker compose up -d
```

## Security notes

- All `.env` files, runtime config directories, and databases are excluded via `.gitignore` — only deployment definitions (`docker-compose.yml`) and `.env.example` placeholders are tracked.
- Passwords referenced in compose files are injected via environment variables, never hardcoded.

## Lessons learned

- Splitting each service into its own folder with its own Compose file made it much easier to reason about dependencies and update services independently, instead of one giant Compose file.
- Runtime config/state (API keys, session tokens, library databases) needs to be gitignored at the directory level (`**/config/`, `**/data/`) — a plain text/secret grep alone isn't enough, since it silently skips over app-specific binary and XML config files.
- Centralized monitoring (Prometheus + Grafana + cAdvisor + node-exporter) made it possible to actually see resource usage per container, which mattered a lot on lower-spec hardware.

## Roadmap

- [ ] Add a self-hosted Gitea instance for private repos and CI runners
- [ ] Auto-deploy via Watchtower on image updates
- [ ] Expand monitoring with alerting rules

## Author

**Reza** — Computer Networks student, LPIC-1
[GitHub](https://github.com/rezayaghobi-dev)
