# Nexus — Artifact Repository & Docker Registry

Sonatype Nexus3 serves as the homelab's self-hosted artifact repository and Docker registry pull-through cache, fronted by Traefik.

See [docker-compose/nexus/](../docker-compose/nexus/) for the deployment files.

## Why

Docker Hub rate limits, regional access issues (see [GitLab CI/CD](GitLab-CICD.md) for the `registry.gitlab.com` geo-block), and the desire for a single place to host internal Docker images all pointed toward a local registry. Nexus3 does that plus more — it can proxy Docker Hub, host private images, and serve as a general Maven/npm/pypi repository if needed.

## What it does

| Capability | Purpose |
|---|---|
| **Docker Hub pull-through cache** | Containers pull from `docker.home.server` instead of Hub directly — avoids rate limits and works even when Hub is slow or blocked |
| **Docker registry (group repo)** | Single endpoint that combines the Hub cache + any private repos |
| **Artifact repository** | Maven, npm, pypi, raw, and other formats — ready for future use |
| **Web UI** | Browse cached images, manage repositories, view connection status |

## Setup

### First boot

```bash
cd docker-compose/nexus
cp .env.example .env   # edit with your values
docker compose up -d
```

Nexus takes 1-2 minutes to fully start (JVM warmup). The health check waits up to 90 seconds before checking.

### Initial admin password

The admin password is set via `NEXUS_SECURITY_INITIAL_PASSWORD` in the `.env` file. After first login at `https://nexus.home.server`, Nexus prompts you to change it.

**Important:** The initial password in `.env` is only used on first boot. After that, Nexus stores its own password in its data volume. Changing the `.env` value afterward does nothing — you change the password through the Nexus UI or REST API.

### Docker registry setup

The Docker registry requires creating a connector port inside Nexus after first boot:

1. Log in to the Nexus web UI
2. Go to **Server Administration → Docker**
3. Create a **HTTP** connector on port `5005` (or whatever `nexus_docker_connector_port` is set to in `.env`)
4. Create a **Docker (proxy)** repository pointing at Docker Hub
5. Create a **Docker (group)** repository that includes the proxy repo
6. The group repo is what clients pull from — its external URL is `https://docker.home.server`

### Configuring Docker daemon on clients

Add the registry as an insecure registry (since it uses a self-signed cert):

```json
{
  "insecure-registries": ["docker.home.server"]
}
```

Or use the `--registry-mirror` flag in the Docker daemon config (set via the Ansible `docker` role).

## Architecture

```
┌──────────────────────────────────────────┐
│              Nexus3 (port 8081)          │
│                                          │
│  ┌─────────────┐  ┌──────────────────┐   │
│  │ Docker Hub  │  │ Docker Group     │   │
│  │ Proxy Repo  │◄─┤ (pull-through    │   │
│  │             │  │  cache + private)│   │
│  └─────────────┘  └───────┬──────────┘   │
│                           │              │
│  ┌────────────────────────┴──────────┐   │
│  │        HTTP Connector :5005       │   │
│  └────────────────────────┬──────────┘   │
└───────────────────────────┼──────────────┘
                            │
                   ┌────────┴────────┐
                   │  Traefik :443   │
                   │  docker.home.   │
                   │  server         │
                   └────────┬────────┘
                            │
                   ┌────────┴────────┐
                   │  Clients pull   │
                   │  from here      │
                   └─────────────────┘
```

### Two Traefik routes

Nexus exposes two domains through Traefik:

| Domain | Backend Port | Purpose |
|---|---|---|
| `nexus.home.server` | 8081 | Web UI and REST API |
| `docker.home.server` | 5005 | Docker registry (pull-through cache) |

Both are routed via Traefik labels in the compose file — no dynamic config YAML needed since Nexus is a proper Docker container on `web_net`.

## Resource usage

Nexus is the heaviest single container in the stack. Current tuning for an 8GB / DDR3 / 4-core host:

| Setting | Value | Notes |
|---|---|---|
| Heap (`-Xms`/`-Xmx`) | 1536m | Below Sonatype's 8GB recommendation but reasonable |
| Direct memory | 512m | For blob store I/O |
| Memory limit | 2560m | Hard cap — container can't exceed this |
| Memory reservation | 1536m | Soft guarantee for scheduling |

With the rest of the stack running, `free -h` typically shows ~3.3GB available. Nexus idles around 1-1.5GB after warmup.

**Do not run Nexus alongside GitLab Omnibus** — together they exceed the host's RAM. The Ansible provisioning playbook can set up either one; pick based on what you need more.

## Networking

- **`web_net`** — front-facing network shared with Traefik (HTTPS access)
- **`app_net`** — internal network for app-to-registry communication (GitLab CI, other services that push/pull images)

The two-network setup keeps the registry accessible to internal services without exposing it through Traefik unnecessarily — though the Docker registry route IS exposed via Traefik for convenience.

## Security notes

- Admin password is set on first boot via environment variable, then managed through the Nexus UI
- Self-signed TLS cert — clients need `insecure-registries` or equivalent trust configuration
- The Docker registry endpoint is LAN-only via Pi-hole DNS
- Nexus stores all data in a Docker named volume (`nexus_data`) — back this up regularly
- REST API access is available at `https://nexus.home.server/service/rest/` — protected by Nexus authentication

## Backups

The `nexus_data` volume contains all repository data, configuration, and the database. To back up:

```bash
docker compose stop nexus
tar czf /backups/nexus-$(date +%Y%m%d).tar.gz -C /var/lib/docker/volumes/nexus_data _data
docker compose start nexus
```

For a hot backup (without stopping), use the Nexus REST API task system to create a backup task through the UI.

## Troubleshooting

- **Slow startup** — Nexus takes 1-2 minutes on first boot. The health check has a 90-second `start_period` before it starts checking. Be patient.
- **"Connection refused" on docker.home.server** — the Docker registry connector port (5005) is created inside Nexus after first boot through the UI. Until that's done, the Docker registry route returns 500.
- **Memory pressure** — if the host starts swapping, reduce `nexus_heap` and `nexus_mem_limit`. Nexus works fine with less memory if you're only using it as a Docker pull-through cache.
- **Geo-blocked registries** — if you're proxying `registry.gitlab.com` and it's geo-blocked (see [GitLab CI/CD](GitLab-CICD.md)), the proxy repo will fail. Use a different upstream or skip that proxy.

## Lessons learned

- Nexus's Docker registry requires a two-step setup: deploy the container first, then create the HTTP connector and repositories through the web UI. There's no way to fully automate the initial repo setup via environment variables — the REST API works but the UI is simpler for first-time setup.
- Running Nexus alongside GitLab Omnibus on an 8GB host is not viable — both are JVM-based and hungry for memory. Pick one, or upgrade the hardware.
- The pull-through cache pattern is genuinely useful even on a home network — it's not just about rate limits, but also about having a local copy when Hub is slow or you're working offline.

[← Back to Home](Home.md)
