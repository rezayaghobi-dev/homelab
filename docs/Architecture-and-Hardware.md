# Architecture and Hardware

## Hardware

The homelab runs on a repurposed always-on Ubuntu Server box — modest specs by design, which shaped a lot of the decisions documented across this wiki (lightweight images, careful resource limits, monitoring everything so problems show up before they cause outages).

| Component | Spec |
|---|---|
| OS | Ubuntu Server |
| Orchestration | Docker + Docker Compose |
| Management UI | Portainer |
| Storage | Mixed SSD + HDD, monitored via Hard Disk Sentinel |

## Design principles

1. **One Compose stack per service.** Each service lives in its own folder with its own `docker-compose.yml`, instead of one giant file. Easier to update, restart, or debug a single service without touching the rest.
2. **Monitor everything.** Prometheus + Grafana + cAdvisor + node-exporter run from day one, not bolted on later — resource pressure on modest hardware shows up fast, and having metrics from the start made it possible to catch it.
3. **Secrets stay out of git.** Every service that needs credentials uses a `.env` file (gitignored) with a matching `.env.example` committed as a template.
4. **DNS-level filtering at the network edge.** Pi-hole sits in front of all DNS traffic rather than relying on per-device ad blockers.

## Network

All services communicate over Docker's internal bridge networks, with only the ports that need external access published to the host. See [Network Services](Network-Services.md) for details on Pi-hole and Portainer specifically.
