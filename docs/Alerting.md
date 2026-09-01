# Alerting

Grafana's built-in unified alerting ties directly into the Prometheus and Loki datasources already running in the [Monitoring Stack](Monitoring-Stack.md) — no separate Alertmanager container needed. All rules, contact points, and notification policies are provisioned as code in `grafana/provisioning/alerting/`, so they survive container rebuilds and are version-controlled alongside everything else in this repo.

## Architecture

```
Prometheus ──┐
             ├──► Grafana Unified Alerting ──► Gmail (SMTP)
Loki ────────┘
```

Grafana evaluates alert rules against its configured datasources (Prometheus for metrics, Loki for logs). When a rule fires, the notification policy routes it to a contact point, which delivers the notification via the configured channel (email over SMTP in this setup).

No separate Alertmanager instance is required — Grafana handles the full pipeline internally.

## Alert rules

All rules live in `docker-compose/monitoring-grafana-promethues-cadvisor-node-exporter/grafana/provisioning/alerting/rules.yaml` under the **Infra** folder:

| Rule | UID | Source | Condition | Severity | Duration |
|---|---|---|---|---|---|
| **Node exporter target down** | `node-down` | Prometheus | `up{job="node_exporter"} < 1` | `critical` | 2 min |
| **High CPU usage** | `high-cpu` | Prometheus | `100 - (avg idle rate) > 85%` | `warning` | 5 min |
| **Error log rate spike** | `loki-error-spike` | Loki | `count_over_time(… \|= "error" [5m]) > 20` | `warning` | 5 min |

### Node exporter target down (`node-down`)

The most critical alert — if the node exporter scrapes as down for 2 minutes, the host itself may be unreachable or the exporter process crashed. Fires at `critical` severity because it means all host-level visibility is lost.

**PromQL:**
```promql
up{job="node_exporter"}
```

**Threshold:** `< 1` (target is down)

### High CPU usage (`high-cpu`)

Watches for sustained CPU usage above 85% across the 5-minute window. The query uses `rate(node_cpu_seconds_total{mode="idle"}[5m])` to smooth out momentary spikes — a brief compile or Docker pull won't trigger it, but a runaway process or resource-hungry container will.

**PromQL:**
```promql
100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Threshold:** `> 85%`

### Error log rate spike (`loki-error-spike`)

Queries Loki for log lines containing "error" across all jobs. If the count exceeds 20 within a 5-minute window and stays elevated for 5 minutes, it fires. This catches application-level issues that metrics alone won't surface — a service that's technically "up" but flooding its logs with errors.

**LogQL:**
```logql
sum(count_over_time({job=~".+"} |= "error" [5m])) or vector(0)
```

**Threshold:** `> 20` error lines in 5 minutes

## Contact points

Defined in `grafana/provisioning/alerting/contactpoints.yaml`:

| Name | Type | Channel |
|---|---|---|
| `gmail-alerts` | Email | SMTP via Gmail App Password |

The email address is set to a placeholder (`YOUR_EMAIL@example.com`) in the provisioned file — update it to your actual address after the first Grafana container starts, or edit it directly in the file before starting.

> **Note:** Grafana provisioning files do not expand Docker environment variables (`${...}` syntax). The email address must be set as a literal string in the YAML.

## Notification policy

Defined in `grafana/provisioning/alerting/policies.yaml`:

| Setting | Value | Meaning |
|---|---|---|
| **Receiver** | `gmail-alerts` | All alerts route to the email contact point |
| **Group by** | `alertname`, `instance` | Alerts with the same name and instance are grouped into a single email |
| **Group wait** | 30s | How long to wait before sending the first notification for a new group |
| **Group interval** | 5 min | Minimum time between notifications for the same group |
| **Repeat interval** | 4 hours | How often to re-notify about an ongoing (unresolved) alert |

This means a firing alert sends its first email within ~30 seconds, groups follow-ups every 5 minutes, and you get a reminder every 4 hours until the alert resolves.

## SMTP configuration

Grafana sends alert emails through Gmail's SMTP relay. The configuration lives in the `grafana` service's environment block in `docker-compose.yml` and pulls credentials from the `.env` file:

```yaml
GF_SMTP_ENABLED=true
GF_SMTP_HOST=smtp.gmail.com:587
GF_SMTP_USER=${GMAIL_SMTP_USER}
GF_SMTP_PASSWORD=${GMAIL_APP_PASSWORD}
GF_SMTP_FROM_ADDRESS=${GMAIL_SMTP_USER}
GF_SMTP_FROM_NAME=Grafana Alerts
```

### Setting up Gmail SMTP

1. Enable 2-Step Verification on your Google account
2. Generate an [App Password](https://myaccount.google.com/apppasswords) (requires 2FA)
3. Add both values to `.env`:
   ```
   GMAIL_SMTP_USER=your-email@gmail.com
   ALERT_EMAIL=your-email@gmail.com
   ```
4. Set the same email as your Grafana login (`GF_SECURITY_ADMIN_USER` in `.env`, or through the Grafana UI)

## How to add new alert rules

Rules are provisioned from YAML — no UI clicks needed:

1. Open `grafana/provisioning/alerting/rules.yaml`
2. Add a new entry under the `rules` list in the `infra-alerts` group
3. Give it a unique `uid`, a descriptive `title`, and set the `datasourceUid` to match your Prometheus (`efck3im1w4pvkf`) or Loki (`P8E80F9AEF21F6940`) datasource
4. Set the `condition` refId to point to the threshold expression
5. Set `for` to how long the condition must be true before firing
6. Add `labels.severity` (`critical`, `warning`, `info`) and an `annotations.summary` message
7. Restart the Grafana container: `docker compose restart grafana`

### Common PromQL examples for new rules

```promql
# Memory usage above 90%
100 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100)

# Disk usage above 85%
100 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100)

# Container restart count (from cAdvisor)
increase(container_restart_count[5m])

# Container memory above limit
container_memory_working_set_bytes / container_spec_memory_limit_bytes
```

## How to add new notification channels

Grafana supports Slack, Discord, PagerDuty, webhooks, and more — all configured through provisioning files:

1. Add a new receiver in `grafana/provisioning/alerting/contactpoints.yaml`
2. Add the channel to the notification policy in `policies.yaml`, or create a new policy that matches specific alert labels
3. Restart Grafana

## Lessons learned

- **Provisioning files don't expand env vars.** Unlike Docker Compose, Grafana's provisioning YAML is read as-is — `${VARIABLE}` syntax is treated as literal text. Email addresses and other non-secret values must be hardcoded in the provisioning files or managed through the Grafana UI after first boot.
- **Promtail is dead.** The `for` duration and `group_interval` in alerting policies interact with log pipeline latency — if using an older Promtail-based setup, log alerts might fire with stale data. Alloy ships logs faster and more reliably, which makes log-based alerts more responsive. See [Monitoring Stack](Monitoring-Stack.md) for the migration details.
- **Alert fatigue is real on small setups.** Three well-tuned rules cover the important failure modes without spamming. Adding too many rules to a single-node homelab generates noise faster than signal — each new rule should answer the question "would I actually get up at 3 AM for this?"
