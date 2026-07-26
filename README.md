# Homelab

A self-hosted homelab running on Docker Compose, built and maintained on an Ubuntu Server. This repo documents the actual infrastructure-as-code behind it — deployment configs only, no runtime data or secrets.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=flat&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu_Server-E95420?style=flat&logo=ubuntu&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)

## Overview

This is a real, running homelab — not a demo. It's deployed on a home Ubuntu server and managed entirely through Docker Compose, with each service isolated in its own folder, and updated through a shared Ansible role run via Semaphore. Configs here are the actual files running in production, with all secrets, API keys, and runtime state stripped out and replaced with `.env.example` placeholders.

## Services

| Service | Folder | Purpose |
|---|---|---|
| **Monitoring stack** | `docker-compose/monitoring-grafana-promethues-cadvisor-node-exporter/` | Prometheus for metrics collection, Grafana for dashboards, cAdvisor for per-container resource stats, node-exporter for host-level metrics |
| **Pi-hole** | `docker-compose/pihole/` | Network-wide DNS-level ad and tracker blocking |
| **Portainer** | `docker-compose/portainer/` | Web UI for managing and monitoring all Docker containers on the host |
| **DockScope** | `docker-compose/dockscope/` | 3D visual dashboard mapping containers, networks, and dependencies, with anomaly detection and crash diagnostics — see [DockScope](docs/DockScope.md) |
| **n8n** | `docker-compose/n8n/` | Workflow automation engine, backed by Postgres |
| **Samba** | `docker-compose/samba/` | Network file sharing across LAN devices |
| **Filebrowser** | `docker-compose/filebrowser/` | Web-based file manager for the server's storage |
| **Media stack** | `docker-compose/mediastack/` | Plex (media server), Sonarr/Radarr/Prowlarr (media automation and indexing), qBittorrent (download client) |
| **Minecraft** | `docker-compose/minecraft/` | Self-hosted game server |
| **Sentinel** | `docker-compose/sentinel/` | Disk health monitoring integrated with smartctl, dumps output to container logs |
| **smartctl** | `docker-compose/smartctl/` | Disk health monitoring (S.M.A.R.T. data) |
| **OpenHands** | `docker-compose/openhands/` | Self-hosted AI coding agent (OpenHands/agent-canvas) backed by Ollama — see [AI Coding Agent](docs/AI-Agent.md) |
| **Nginx Proxy Manager** | `docker-compose/nginx-proxy-manager/` | Reverse proxy giving every service a friendly `.home` hostname with locally-trusted HTTPS — see [Reverse Proxy](docs/Reverse-Proxy.md) |
| **Semaphore** | `docker-compose/semaphore/` | Self-hosted Ansible UI (alternative to AWX) — see [Semaphore Guide](docs/Semaphore.md) |
| **Ansible playbooks** | `ansible/` | Shared update role (pull → recreate → health-check → prune) reused across every stack, run via Semaphore — see [Ansible Playbooks](docs/AnsiblePlaybooks.md) |

## Learning labs (not always-on)

Not everything in this repo runs permanently. Some folders are kept purely as reference from one-off learning exercises for my DevOps cert coursework — the compose files work, but they're not part of the day-to-day stack above.

| Lab | Folder | Purpose |
|---|---|---|
| **Elastic Stack (ELK)** | `docker-compose/elk/` | Elasticsearch + Kibana, security-enabled, sized for this hardware — a modern-workflow (Elastic Agent/Fleet) alternative to an older Filebeat/Metricbeat-based course reference. Not run continuously since Prometheus/Grafana already cover monitoring here — see [Elastic Stack (ELK)](docs/ElasticStack.md) |

## Repository structure

```
homelab/
├── docker-compose/
│   ├── monitoring-grafana-promethues-cadvisor-node-exporter/
│   │   └── docker-compose.yml
│   ├── pihole/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   ├── portainer/
│   │   └── docker-compose.yml
│   ├── dockscope/
│   │   └── docker-compose.yml
│   ├── n8n/
│   │   ├── docker-compose.yaml
│   │   └── .env.example
│   ├── samba/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   ├── filebrowser/
│   │   └── docker-compose.yml
│   ├── mediastack/
│   │   ├── plex/docker-compose.yml
│   │   ├── sonarr/docker-compose.yml
│   │   ├── radarr/docker-compose.yml
│   │   ├── prowlarr/docker-compose.yml
│   │   ├── whisparr/docker-compose.yml
│   │   └── download-client-qbittorent/docker-compose.yml
│   ├── minecraft/
│   │   └── docker-compose.yml
│   ├── sentinel/
│   │   └── docker-compose.yml
│   ├── smartctl/
│   │   └── docker-compose.yml
│   ├── openhands/
│   │   └── docker-compose.yaml
│   ├── nginx-proxy-manager/
│   │   └── docker-compose.yaml
│   ├── semaphore/
│   │   ├── docker-compose.yml
│   │   └── README.md
│   └── elk/
│       ├── docker-compose.yml
│       └── .env.example
├── ansible/
│   └── playbooks/
│       ├── roles/
│       │   └── docker_compose_update/
│       │       └── tasks/main.yml
│       ├── update-filebrowser.yml
│       ├── update-n8n.yml
│       ├── update-npm.yml
│       ├── update-pihole.yml
│       ├── update-plex.yml
│       ├── update-portainer.yml
│       ├── update-prowlarr.yml
│       ├── update-radarr.yml
│       ├── update-samba.yml
│       ├── update-sentinel.yml
│       ├── update-smartctl.yml
│       ├── update-sonarr.yml
│       ├── update-whisparr.yml
│       ├── update-agent-canvas.yml
│       ├── update-grafana.yml
│       └── ping.yml
├── docs/
│   ├── Home.md
│   ├── Architecture-and-Hardware.md
│   ├── Monitoring-Stack.md
│   ├── Network-Services.md
│   ├── Media-Automation.md
│   ├── Workflow-Automation.md
│   ├── Storage-Health.md
│   ├── AI-Agent.md
│   ├── Reverse-Proxy.md
│   ├── Lessons-Learned.md
│   ├── Semaphore.md
│   ├── DockScope.md
│   ├── AnsiblePlaybooks.md
│   ├── ElasticStack.md
│   └── images/
└── .gitignore
```

## Running a service

Each folder is a standalone Compose stack:

```bash
cd docker-compose/pihole
cp .env.example .env   # fill in real values
docker compose up -d
```

## Updating a service

Rather than pulling and recreating manually, every always-on stack has a matching Ansible playbook that pulls the latest images, recreates containers, verifies they're healthy, and prunes unused images — run through Semaphore's web UI. See [Ansible Playbooks](docs/AnsiblePlaybooks.md) for details on how the shared role works.

## Security notes

- All `.env` files, runtime config directories, and databases are excluded via `.gitignore` — only deployment definitions (`docker-compose.yml`) and `.env.example` placeholders are tracked.
- Passwords referenced in compose files are injected via environment variables, never hardcoded.
- The AI coding agent (`docker-compose/openhands/`) currently uses a third-party API aggregator as its LLM backend — see [AI Coding Agent](docs/AI-Agent.md) for details and caveats. It has no access to the Docker socket or other containers on the host.
- **DockScope** (`docker-compose/dockscope/`) mounts `/var/run/docker.sock`, the same as Portainer — this grants it effectively root-equivalent access to the Docker host, and it currently has no built-in authentication on its web UI, so it's kept LAN-only and not exposed through the reverse proxy. See [DockScope](docs/DockScope.md).

## Lessons learned

- Splitting each service into its own folder with its own Compose file made it much easier to reason about dependencies and update services independently, instead of one giant Compose file.
- Runtime config/state (API keys, session tokens, library databases) needs to be gitignored at the directory level (`**/config/`, `**/data/`) — a plain text/secret grep alone isn't enough, since it silently skips over app-specific binary and XML config files.
- Centralized monitoring (Prometheus + Grafana + cAdvisor + node-exporter) made it possible to actually see resource usage per container, which mattered a lot on lower-spec hardware.
- Free-tier cloud AI APIs enforce regional access restrictions automatically — worth checking a provider's terms before building around "free tier" as an assumption. See [AI Coding Agent](docs/AI-Agent.md).
- Wildcard TLS certs (`*.home`) are rejected by browsers on single-label local domains — certificates for local reverse proxies need explicit hostnames listed instead. See [Reverse Proxy](docs/Reverse-Proxy.md).
- Grouping all Compose stacks under one `docker-compose/` folder (rather than flat at repo root) kept the structure readable once Ansible playbooks were added as a sibling — a flat repo mixing deployment configs and automation code got confusing fast.
- Newer Docker images can silently raise the minimum CPU generation required (base-OS changes, not anything in the compose file itself) — hit this running Elasticsearch 9.x on older hardware. See [Elastic Stack (ELK)](docs/ElasticStack.md).

## Roadmap

- [ ] Add a self-hosted Gitea instance for private repos and CI runners
- [ ] Auto-deploy via Watchtower on image updates
- [ ] Expand monitoring with alerting rules

## Author

**Reza** — Computer Networks student, LPIC-1
[GitHub](https://github.com/rezayaghobi-dev)
