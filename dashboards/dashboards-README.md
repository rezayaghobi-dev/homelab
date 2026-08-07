# Dashboards

Grafana dashboard exports, kept as JSON so they're versioned alongside the infrastructure they visualize instead of only existing inside Grafana's own database.

## `gitlab-application-runner-metrics.json`

Custom-built dashboard for the self-hosted GitLab instance and its Runner — see [GitLab CI/CD](../docs/GitLab-CICD.md) for the full write-up of why this is hand-built rather than an imported community dashboard.

**Data sources required:** Prometheus (metrics) and Loki (logs), both already provisioned by the [monitoring stack](../docker-compose/monitoring-grafana-promethues-cadvisor-node-exporter/).

### Rows

| Row | Panels |
|---|---|
| **GitLab Rails & Puma Overview** | Request queue latency (p95 / avg), Puma memory watchdog limit, live nginx/workhorse logs (Loki) correlated against the same timeline |
| **Database & Redis Performance** | Postgres and Redis metrics |
| **Cache & CI Metrics** | Rails cache performance, CI pipeline metrics |
| **GitLab Runner Metrics** | Active jobs vs. concurrency limit, job execution duration, job errors/sec, Runner process memory footprint |

Pulling live logs into the same row as request latency (rather than a separate Loki-only dashboard) was a deliberate choice — when Puma queue latency spikes, the correlated nginx/workhorse log lines are visible in the same view without switching to Explore.

### Importing

**Grafana → Dashboards → New → Import → Upload JSON file**, select `gitlab-application-runner-metrics.json`, map the `DS_PROMETHEUS` variable to your Prometheus data source when prompted.

### Metric naming note

Panels query GitLab's own `/-/metrics` endpoint directly (e.g. `gitlab_rails_queue_duration_seconds_bucket`, `process_resident_memory_bytes{job="gitlab-runner"}`) — these metric names come from an *externally scraped* GitLab instance with its bundled Omnibus monitoring disabled. If reusing this dashboard against a GitLab instance running its own internal Prometheus (Omnibus monitoring enabled), the metric names and job labels won't match and panels will show no data.
