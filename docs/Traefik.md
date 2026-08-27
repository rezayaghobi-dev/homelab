# Traefik — Reverse Proxy

Traefik replaced Nginx Proxy Manager as the homelab's reverse proxy, giving every service a `<service>.home.server` hostname with locally-trusted HTTPS — now configured entirely as code instead of a web UI.

See the [Traefik README](../docker-compose/traefik/README.md) for the full file-by-file breakdown and how to add new services.

## Why the migration

Two reasons, both rooted in the same observation: NPM works, but it doesn't scale with the rest of the infrastructure-as-code approach.

**Everything as code.** NPM's configuration lives entirely in its web UI — proxy hosts, SSL certs, custom locations, access rules. None of it is version-controlled or reproducible. If the data volume is lost, you're rebuilding every proxy host manually. Traefik's routes, middlewares, and TLS config are all YAML files in this repo — diffable, reviewable, reproducible with `docker compose up -d`.

**Docker daemon auto-discovery.** NPM requires manually adding each proxy host through its UI — domain, target IP/port, SSL cert, save. Every new service means another round-trip through a different tool. Traefik watches the Docker daemon directly and picks up containers with `traefik.enable=true` automatically. Adding a new service to the reverse proxy is a two-line label addition to that service's compose file.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Traefik v3.7                      │
│                                                     │
│  Entrypoints:  :80 (HTTP)  →  redirect to HTTPS     │
│                :443 (HTTPS) →  route to service      │
│                                                     │
│  Providers:                                         │
│    Docker daemon  →  auto-discovers labeled conns    │
│    File provider  →  watches dynamic/ for YAML       │
│                                                     │
│  TLS:  mkcert local CA, single cert for all hosts   │
└─────────────────────────────────────────────────────┘
         │              │              │
    ┌────┴────┐   ┌─────┴─────┐  ┌────┴────┐
    │  Docker  │   │  File     │  │  certs/ │
    │  labels  │   │  dynamic/ │  │  mkcert │
    │  per-svc │   │  routes   │  │  CA     │
    └─────────┘   └───────────┘  └─────────┘
```

### Static config

Passed as command-line flags in `compose.yaml`:

- **Docker provider** — watches for labeled containers on `web_net`
- **File provider** — hot-reloads `dynamic/` directory
- **Entrypoints** — `:80` and `:443`
- **Ping** — health check endpoint
- **API dashboard** — enabled, secured via its own HTTPS route

### Dynamic config (`dynamic/`)

| File | Purpose |
|---|---|
| `tls.yaml` | Default TLS cert store pointing at the mkcert certificate |
| `middlewares.yaml` | `redirect-to-https` (301) + `security-headers` (HSTS, XSS, nosniff, SAMEORIGIN) |
| `pihole.yaml` | Pi-hole route (host-network, can't use Docker labels) |
| `plex.yml` | Plex route (external host `192.168.100.6:32400`) |
| `sentinel.yml` | Sentinel route (external host `192.168.100.6:8088`) |
| `dockscope-auth.yml` | BasicAuth middleware for DockScope (Docker socket access) |

### Services fronted by Traefik

| Service | Hostname | Method |
|---|---|---|
| Prometheus | `prometheus.home.server` | Docker labels |
| Grafana | `grafana.home.server` | Docker labels |
| cAdvisor | `cadvisor.home.server` | Docker labels |
| Loki | `loki.home.server` | Docker labels |
| Alloy | `alloy.home.server` | Docker labels |
| Pi-hole | `pihole.home.server` | File provider |
| Portainer | `portainer.home.server` | Docker labels |
| n8n | `n8n.home.server` | Docker labels |
| Filebrowser | `filebrowser.home.server` | Docker labels |
| DockScope | `dockscope.home.server` | Docker labels + basicAuth |
| Semaphore | `semaphore.home.server` | Docker labels |
| MinIO | `minio.home.server` | Docker labels |
| Plex | `plex.home.server` | File provider (external) |
| Sentinel | `sentinel.home.server` | File provider (external) |
| Vaultwarden | `vaultwarden.home.server` | Docker labels |
| Traefik Dashboard | `traefik.home.server` | Docker labels |

## TLS certificates

Same approach as the NPM era — [mkcert](https://github.com/FiloSottile/mkcert) creates a local CA trusted on each device, then signs a single certificate covering all `*.home.server` hostnames. The cert and key live in `traefik/certs/` and are mounted read-only.

Traefik's file-based TLS store (`dynamic/tls.yaml`) applies this cert as the default for all routes — no per-host certificate assignment needed. Adding a new `.home.server` hostname automatically gets the right cert.

## Network

All Traefik-fronted services join the `web_net` external Docker network:

```bash
docker network create web_net
```

Services that can't join `web_net` (host-network containers like Pi-hole, or external machines like Plex) are routed via the file provider with explicit IP:port targets.

## Adding a new service

1. **Docker container on `web_net`** — add Traefik labels to its compose file
2. **Host-network or external** — create a YAML file in `dynamic/`
3. **Pi-hole** — add DNS record for `<service>.home.server`

No restart required — Traefik auto-discovers Docker label changes and hot-reloads file provider changes.

## Port 80/443 conflict with Pi-hole

Pi-hole runs in `network_mode: host`, which means it binds directly to ports 80 and 443 for its web UI — the same ports Traefik needs. Resolved by moving Pi-hole's web interface to port 8082 via the FTL environment variable:

```yaml
environment:
  FTLCONF_webserver_port: '8082o,[::]:8082o'
```

Pi-hole's DNS service (port 53) is untouched — only its web UI moved. See [Reverse Proxy](Reverse-Proxy.md) for the full history of this port conflict.

## Security notes

- Dashboard is LAN-only via Pi-hole DNS (not exposed publicly)
- DockScope has basicAuth in addition to HTTPS (Docker socket access)
- All HTTP → HTTPS redirects are permanent (301)
- Security headers: HSTS (1 year, includeSubdomains, preload), XSS filter, content-type nosniff, SAMEORIGIN framing

## Lessons learned

- Traefik's Docker label approach means the reverse proxy configuration is co-located with each service — no separate tool or UI to maintain. This matches the "each service is a folder" philosophy the rest of the homelab already follows.
- File-based routes in `dynamic/` are useful for services that can't use Docker labels (host-network containers, external machines). Keeping them as separate YAML files makes it obvious which services use which routing method.
- The `web_net` external network is a hard requirement — Traefik can only route to containers on networks it's connected to. Forgetting to add a new service to `web_net` is the most common "why isn't my route working" issue.
- Hot-reloading (file provider + Docker provider) means zero-downtime config changes — a major operational improvement over NPM, which required a container restart for some config changes.

[← Back to Home](Home.md)
