# Homelab

A self-hosted homelab running on Docker Compose, built and maintained on an Ubuntu Server. This repo documents the actual infrastructure-as-code behind it — deployment configs only, no runtime data or secrets.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=flat&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu_Server-E95420?style=flat&logo=ubuntu&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/Loki-F5A623?style=flat&logo=grafana&logoColor=white)

## Overview

This is a real, running homelab — not a demo. It's deployed on a home Ubuntu server and managed entirely through Docker Compose, with each service isolated in its own folder, and updated through a shared Ansible role run via Semaphore. Configs here are the actual files running in production, with all secrets, API keys, and runtime state stripped out and replaced with `.env.example` placeholders.

## Services

| Service | Folder | Purpose |
|---|---|---|
| **Monitoring stack** | `docker-compose/monitoring-grafana-promethues-cadvisor-node-exporter/` | Prometheus for metrics, Grafana for dashboards, cAdvisor for per-container resource stats, node-exporter for host-level metrics, plus Loki + Grafana Alloy for centralized container log aggregation — see [Monitoring Stack](docs/Monitoring-Stack.md) |
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
| **GitLab CI/CD** | `docker-compose/gitlab/` | Self-hosted GitLab Omnibus + Docker-executor Runner, tuned for this hardware and integrated with the monitoring stack — see [GitLab CI/CD](docs/GitLab-CICD.md) |
| **Custom CI images** | `docker-compose/gitlab/ci-images-reference/` | Self-built, minimal Docker images for CI pipelines, stored in a self-hosted Container Registry, rebuilt biweekly — see [Custom CI Runner Images](docs/CI-Custom-Images.md) |
| **Voting app CI/CD** | `voting-app-monorepo` (self-hosted GitLab, referenced here) | Full pipeline: build, test, vulnerability scan, 3-environment deploy with rollback, load test, DB backup to MinIO — see [Voting App — Mono-Repo](docs/Voting-App-Monorepo.md) |
| **Object storage** | `docker-compose/minio/` | Self-hosted MinIO (S3-compatible), `-cpuv1` release tag for CPU compatibility — backup target for the voting app's Postgres dumps |

## Learning labs (not always-on)

Not everything in this repo runs permanently. Some folders are kept purely as reference from one-off learning exercises for my DevOps cert coursework — the compose files work, but they're not part of the day-to-day stack above.

| Lab | Folder | Purpose |
|---|---|---|
| **Elastic Stack (ELK)** | `docker-compose/elk/` | Elasticsearch + Kibana, security-enabled, sized for this hardware — a modern-workflow (Elastic Agent/Fleet) alternative to an older Filebeat/Metricbeat-based course reference. Not run continuously since Loki now covers centralized logging here — see [Elastic Stack (ELK)](docs/ElasticStack.md) |

## Repository structure

```
homelab/
├── docker-compose/
│   ├── monitoring-grafana-promethues-cadvisor-node-exporter/
│   │   ├── docker-compose.yml
│   │   ├── alloy/
│   │   │   └── config.alloy
│   │   ├── grafana/
│   │   │   └── provisioning/
│   │   │       └── datasources/
│   │   │           └── loki.yml
│   │   └── prometheus/
│   │       └── prometheus.yml
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
│   ├── minio/
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
│   ├── gitlab/
│   │   ├── docker-compose.yml
│   │   ├── config.toml.example
│   │   ├── ci-images-reference/
│   │   │   ├── README.md
│   │   │   ├── .gitlab-ci.yml
│   │   │   └── images/
│   │   │       └── ssh-alpine/
│   │   │           └── Dockerfile
│   │   └── backups/
│   │       └── gitlab-backup.sh
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
│   ├── GitLab-CICD.md
│   ├── CI-Custom-Images.md
│   ├── Voting-App-Monorepo.md
│   ├── ElasticStack.md
│   └── images/
├── dashboards/
│   └── gitlab-application-runner-metrics.json
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
- **Grafana Alloy** (part of the monitoring stack) also mounts `/var/run/docker.sock` read-only, needed to discover containers and tail their logs.

## Lessons learned

- Splitting each service into its own folder with its own Compose file made it much easier to reason about dependencies and update services independently, instead of one giant Compose file.
- Runtime config/state (API keys, session tokens, library databases) needs to be gitignored at the directory level (`**/config/`, `**/data/`) — a plain text/secret grep alone isn't enough, since it silently skips over app-specific binary and XML config files.
- Centralized monitoring (Prometheus + Grafana + cAdvisor + node-exporter) made it possible to actually see resource usage per container, which mattered a lot on lower-spec hardware.
- Free-tier cloud AI APIs enforce regional access restrictions automatically — worth checking a provider's terms before building around "free tier" as an assumption. See [AI Coding Agent](docs/AI-Agent.md).
- Wildcard TLS certs (`*.home`) are rejected by browsers on single-label local domains — certificates for local reverse proxies need explicit hostnames listed instead. See [Reverse Proxy](docs/Reverse-Proxy.md).
- Grouping all Compose stacks under one `docker-compose/` folder (rather than flat at repo root) kept the structure readable once Ansible playbooks were added as a sibling — a flat repo mixing deployment configs and automation code got confusing fast.
- Newer Docker images can silently raise the minimum CPU generation required (base-OS changes, not anything in the compose file itself) — hit this running Elasticsearch 9.x on older hardware. See [Elastic Stack (ELK)](docs/ElasticStack.md).
- **Promtail is end-of-life as of March 2026** and removed outright as of Loki 3.7.3 — any current Loki setup should use Grafana Alloy for log shipping instead. Worth checking a project's actual current-recommended tooling before following an older tutorial, since agent names and workflows in this space have moved fast.
- Bind-mounted container data directories can end up owned by the wrong UID after mixing `sudo` and non-`sudo` commands on the same folder — this silently broke Loki's ability to write its own working directory, surfacing only as a `permission denied` deep in its startup logs.
- Community Grafana dashboards built for older Loki/Promtail label conventions (e.g. `container_name`) don't automatically work against a fresh Alloy-based label schema (`container`, `service_name`) — worth checking a dashboard's expected labels against your actual pipeline's labels before assuming an import error means something's broken on your end.
- GitLab Omnibus's default RAM footprint assumes dedicated hardware — running it alongside an existing stack requires trimming Puma/Sidekiq workers explicitly, and disabling GitLab's own bundled monitoring in favor of the stack already running here.
- `registry.gitlab.com` is geo-blocked under U.S. sanctions for several countries at the infrastructure level, independent of any account or token — surfaced as a Docker-executor helper-image pull failure. Fix was sourcing the helper image from Docker Hub instead. See [GitLab CI/CD](docs/GitLab-CICD.md).
- Files written by a root-running container into a bind-mounted volume (GitLab's `config/`, `data/backups/`) are root-owned on the host — a backup script touching these needs to run as root and `chown` its own output back to the regular user, or every later interaction with the backup needs `sudo`.
- Tailscale actively manages `/etc/resolv.conf` on a host it's installed on, silently overriding local DNS resolvers (Pi-hole) even when `systemd-resolved` is configured correctly — worth checking `/etc/resolv.conf`'s own header before assuming a DNS setup is broken. See [Custom CI Runner Images](docs/CI-Custom-Images.md).
- GitLab's Container Registry ties every image path to a real, existing project — unlike Docker Hub, pushing to an arbitrary namespace that has no matching project fails with a generic-looking `denied: requested access` error that reads like an auth problem but isn't one.
- Docker images with `ENTRYPOINT` hardcoded to the tool itself (Trivy, k6, MinIO's `mc`) break GitLab CI's default script invocation with a confusing "unknown command sh" error — fixed the same way every time with `entrypoint: [""]`. See [Voting App — Mono-Repo](docs/Voting-App-Monorepo.md).
- In Docker-outside-of-Docker setups, bind mounts (`-v host:container`) always resolve against the **host's** filesystem regardless of which container issued the `docker run` command — `docker cp` is the correct way to move a file into a container across that boundary, not a shared path assumption.
- MinIO's current images require `x86-64-v2` CPU instructions and crash outright on older hardware (Phenom II here) with a `Fatal glibc error` — fixed by pinning to a `-cpuv1` release tag, a legacy compatibility branch MinIO still publishes for exactly this case.

## Roadmap

- [x] ~~Add a self-hosted Gitea instance for private repos and CI runners~~ — done via self-hosted GitLab instead, see [GitLab CI/CD](docs/GitLab-CICD.md)
- [ ] Auto-deploy via Watchtower on image updates
- [ ] Expand monitoring with alerting rules

## Author

**Reza** — Computer Networks student, LPIC-1
[GitHub](https://github.com/rezayaghobi-dev)
