# Traefik

Self-hosted reverse proxy replacing Nginx Proxy Manager — gives every service a friendly `<service>.home.server` hostname with locally-trusted HTTPS, configured entirely as code.

## Why the migration from Nginx Proxy Manager

NPM works fine, but the switching cost grew as the homelab did. Two things pushed the move:

### 1. Infrastructure as code

NPM's entire configuration lives behind a web UI — proxy hosts, SSL certificates, custom locations, access rules. None of it is version-controlled, exportable, or reproducible. If the container dies and comes back without its data volume, you're rebuilding every proxy host by hand.

Traefik is the opposite: every route, middleware, TLS cert, and entrypoint is defined in YAML files that live in this repo. The compose file, the `dynamic/` configs, the cert files — all version-controlled, all diffable, all reproducible with `docker compose up -d`. This is the same pattern the rest of the homelab already follows (each service is a Compose file in a folder), and Traefik fits that model naturally where NPM didn't.

### 2. Docker daemon auto-discovery

NPM requires you to manually add each proxy host through its web UI — type the domain, point it at the container's IP and port, attach an SSL cert, save. Every new service means another round-trip through the UI.

Traefik talks directly to the Docker daemon and watches for containers with `traefik.enable=true`. Add a few labels to any compose file and Traefik picks up the new route automatically — no UI interaction, no restart, no manual configuration. This means adding a new service to the reverse proxy is a two-line addition to that service's compose file, not a separate step in a different tool.

## How it works

```
traefik/
├── compose.yaml          # Traefik container + static config
├── certs/                # Local TLS certificates (mkcert)
│   ├── home.server.crt
│   └── home.server.key
└── dynamic/              # File-based provider — routes, middlewares, TLS
    ├── tls.yaml          # Default TLS cert store
    ├── middlewares.yaml  # HTTPS redirect + security headers
    ├── pihole.yaml       # Pi-hole route
    ├── plex.yml          # Plex route (external host)
    ├── sentinel.yml      # Sentinel route (external host)
    └── dockscope-auth.yml # Basic auth middleware for DockScope
```

### Static config (`compose.yaml`)

Traefik's static configuration is passed as command-line flags:

- **Docker provider** — watches the Docker daemon for labeled containers on the `web_net` network
- **File provider** — watches `/dynamic/` for YAML config changes (hot-reloaded, no restart needed)
- **Entrypoints** — `:80` (HTTP) and `:443` (HTTPS)
- **API dashboard** — enabled but not insecure (accessed via its own HTTPS route)

### Dynamic config (`dynamic/`)

Routes and middlewares are defined as YAML files, not labels. This keeps the compose files clean and makes it easy to see all routing rules in one place:

- **`middlewares.yaml`** — shared `redirect-to-https` and `security-headers` middlewares (HSTS, XSS filter, content-type nosniff, SAMEORIGIN framing)
- **`tls.yaml`** — default TLS cert store pointing at the mkcert-generated certificate
- **`pihole.yaml`**, **`plex.yml`**, **`sentinel.yml`** — per-service route definitions for services that can't use Docker labels (host-network or external hosts)

### Services using Docker labels

Most services define their Traefik routes directly in their compose files via labels:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=web_net"
  - "traefik.http.routers.<service>.rule=Host(`<service>.home.server`)"
  - "traefik.http.routers.<service>.entrypoints=websecure"
  - "traefik.http.routers.<service>.tls=true"
  - "traefik.http.routers.<service>.middlewares=security-headers@file"
  - "traefik.http.routers.<service>-http.rule=Host(`<service>.home.server`)"
  - "traefik.http.routers.<service>-http.entrypoints=web"
  - "traefik.http.routers.<service>-http.middlewares=redirect-to-https@file"
  - "traefik.http.services.<service>.loadbalancer.server.port=<internal-port>"
```

Services currently fronted by Traefik:

| Service | Hostname | Internal Port |
|---|---|---|
| Prometheus | `prometheus.home.server` | 9090 |
| Grafana | `grafana.home.server` | 3000 |
| cAdvisor | `cadvisor.home.server` | 8080 |
| Loki | `loki.home.server` | 3100 |
| Alloy | `alloy.home.server` | 12345 |
| Pi-hole | `pihole.home.server` | 8082 (host) |
| Portainer | `portainer.home.server` | 9000 |
| n8n | `n8n.home.server` | 5678 |
| Filebrowser | `filebrowser.home.server` | 80 |
| DockScope | `dockscope.home.server` | 4681 |
| Semaphore | `semaphore.home.server` | 3000 |
| MinIO | `minio.home.server` | 9001 |
| Plex | `plex.home.server` | 32400 (external) |
| Sentinel | `sentinel.home.server` | 8088 (external) |
| Vaultwarden | `vaultwarden.home.server` | 80 |
| Traefik Dashboard | `traefik.home.server` | API@internal |

## TLS certificates

Same approach as before — [mkcert](https://github.com/FiloSottile/mkcert) generates a local CA and signs certificates for `*.home.server`. The cert and key live in `certs/` and are mounted read-only into the Traefik container.

Traefik loads the default cert via `dynamic/tls.yaml`:

```yaml
tls:
  stores:
    default:
      defaultCertificate:
        certFile: /certs/home.server.crt
        keyFile: /certs/home.server.key
```

Adding a new service with a `.home.server` hostname automatically gets the right cert — no per-host certificate assignment needed.

## Adding a new service

1. **If the service is a Docker container on `web_net`** — add Traefik labels to its compose file (copy the pattern from any existing service above)
2. **If the service is host-network or external** — create a new YAML file in `dynamic/` with the router and service definition
3. **Add the hostname to Pi-hole** — so DNS resolves `<service>.home.server` to the server's LAN IP

No restart required — Traefik watches both the Docker daemon and the `dynamic/` directory and picks up changes automatically.

## Network

All Traefik-fronted services join the `web_net` external Docker network. This network must be created before starting Traefik:

```bash
docker network create web_net
```

## Security notes

- The Traefik dashboard is behind its own HTTPS route with security headers — not exposed on the public internet, LAN-only via Pi-hole DNS
- DockScope additionally uses a basicAuth middleware (`dynamic/dockscope-auth.yml`) since it mounts the Docker socket
- All HTTP requests are redirected to HTTPS permanently (301)
- Security headers include HSTS (1 year, includeSubdomains, preload), XSS filter, content-type nosniff, and SAMEORIGIN framing

[← Back to Home](../../docs/Home.md)
