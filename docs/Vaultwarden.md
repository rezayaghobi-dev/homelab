# Vaultwarden

Self-hosted password manager — a lightweight, Rust-based implementation of the Bitwarden server API, giving full Bitwarden client compatibility (browser extensions, mobile apps, desktop apps) without Bitwarden's cloud dependency.

See [docker-compose/vaultwarden/](../docker-compose/vaultwarden/) for the deployment files.

## Why

After years of managing passwords across various tools, a self-hosted password manager was the missing piece. Vaultwarden provides:

- **Full Bitwarden compatibility** — works with the official Bitwarden browser extension, iOS/Android apps, and desktop apps. No proprietary client lock-in.
- **Lightweight** — single container, SQLite database, minimal resource usage. Runs comfortably alongside the rest of the stack.
- **Local data ownership** — passwords never leave the LAN unless you want them to (via Bitwarden's sync protocol for mobile access outside the home).
- **Long passwords** — using Vaultwarden as the source of truth for 30+ character passwords across all services, replacing the short memorable passwords that were previously hardcoded in compose files.

## Setup

### Initial configuration

```bash
cd docker-compose/vaultwarden
docker compose up -d
```

Access the web UI at `vaultwarden.home.server` (via Traefik) or `http://localhost:8084` directly.

**First step:** create your admin account, then set `SIGNUPS_ALLOWED=false` in the compose file to prevent new registrations.

### Generating password hashes

Vaultwarden uses the same `admin_token` mechanism as Bitwarden for admin access. For the Traefik basicAuth middleware (DockScope), generate hashes with:

```bash
htpasswd -nB <username>
```

This produces bcrypt-hashed entries compatible with Traefik's basicAuth middleware.

## Integration with the homelab

### Traefik routing

Vaultwarden is fronted by Traefik with the standard label set:

- `vaultwarden.home.server` → HTTPS → container port 80
- HTTP → HTTPS redirect
- Security headers middleware

### Password management workflow

1. Store all service passwords in Vaultwarden (30+ character randomly generated)
2. Reference passwords via `.env` files on the host (not in compose files)
3. Compose files use `${VARIABLE}` references, never hardcoded values

This is the migration path from the previous approach of short, memorable passwords hardcoded in compose files — the Traefik migration was the catalyst for adopting proper secret management across the stack.

## Configuration

Key environment variables in `docker-compose.yml`:

| Variable | Value | Purpose |
|---|---|---|
| `WEBSOCKET_ENABLED` | `true` | Enable real-time sync with Bitwarden clients |
| `SIGNUPS_ALLOWED` | `false` | Disable new account creation after initial setup |

Data is stored in `./vw-data/` (gitignored).

## Security notes

- Signups are disabled after initial account creation
- The web UI is only accessible via HTTPS through Traefik (LAN-only via Pi-hole DNS)
- Vaultwarden encrypts all vault data client-side before transmission — even if the server is compromised, passwords remain encrypted
- The `vw-data/` directory contains the SQLite database and should be backed up regularly
- Admin panel is accessible at `vaultwarden.home.server/admin` (requires admin token)

## Backups

The SQLite database in `vw-data/` should be backed up as part of the regular backup strategy. A simple approach:

```bash
# stop the container, copy the data, restart
docker compose stop vaultwarden
cp -r vw-data/ /backups/vaultwarden-$(date +%Y%m%d)/
docker compose start vaultwarden
```

Or use the Bitwarden CLI to export a JSON/CSV backup from within the web UI.

## Lessons learned

- Migrating from hardcoded passwords to a password manager is painful but worth it — the Traefik migration forced the cleanup, and now every service uses proper secret references.
- 30+ character passwords are free with a password manager — there's no reason to use short, memorable passwords for services that only need them in `.env` files.
- Vaultwarden's Bitwarden compatibility means you don't have to convince family members to use a different app — the official Bitwarden clients just work.
- The `SIGNUPS_ALLOWED` flag is easy to forget — leave it `true` too long and anyone on the LAN can create an account.

[← Back to Home](Home.md)
