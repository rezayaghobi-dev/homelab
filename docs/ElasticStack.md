# Elastic Stack (ELK)

A hands-on lab for the observability chapter of my DevOps cert — not a permanent part of this homelab's monitoring, since Prometheus + Grafana + cAdvisor + node-exporter already cover that role here.

## Why

My course's reference material for this chapter is a few years old — it walks through a basic ELK setup (Elasticsearch + Logstash + Kibana) with security disabled and metrics wired in by hand through separate Beats agents. That workflow has since been superseded: the current recommended approach centers on a single **Elastic Agent**, centrally managed through **Fleet** in Kibana, with pre-built **Integrations** replacing hand-configured Filebeat/Metricbeat setups. This lab was about running the current version of that workflow rather than the older one, purely to understand it for the cert — not to replace the monitoring stack already documented in [Monitoring Stack](Monitoring-Stack.md).

## What actually got deployed

Elasticsearch + Kibana, secured (not the "turn off X-Pack security" pattern from older tutorials), sized for this hardware. Fleet/Elastic Agent integrations were browsed (System, Docker) but not fully enrolled before the lab was torn down — see [Semaphore](Semaphore.md) and [Ansible Playbooks](AnsiblePlaybooks.md) for the pattern this homelab actually uses for ongoing service management; ELK wasn't kept running long enough to need either.

```yaml
services:
  elasticsearch:
    image: elasticsearch:8.19.19
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=false
      - xpack.ml.enabled=false
      - ES_JAVA_OPTS=-Xms1g -Xmx1g
    mem_limit: 1500m

  kibana:
    image: kibana:8.19.19
    environment:
      - NODE_OPTIONS=--max-old-space-size=1024
    mem_limit: 1200m
```

(Full compose file with the setup container that provisions the `kibana_system` password is in `docker-compose/elk/`.)

## Hardware roadblocks — the actually useful part of this lab

Two CPU-specific failures came up, both worth documenting since they're the kind of thing that doesn't show up until you try running current-generation software on older hardware:

**1. `Fatal glibc error: CPU does not support x86-64-v2`**

Elasticsearch 9.x's Docker image failed outright on this box's CPU (AMD Phenom II, 2009-era). This turned out to be a base-OS change on Elastic's side — their 9.x images switched base images in a way that assumes a CPU baseline (`x86-64-v2`: SSE4.2, CMPXCHG16B, POPCNT) that this CPU predates by about two years. Fix: pinned to the **8.19.x branch**, which still targets an older baseline and started fine. Still a current, actively patched release (supported through mid-2027) — not a step back to something outdated.

**2. `Failure running machine learning native code`**

Elasticsearch's ML module ships a native binary that also failed to run on this CPU. ML wasn't needed for this lab (it's for anomaly detection, unrelated to basic log/metric ingestion), so it was disabled outright with `xpack.ml.enabled=false` rather than chased further.

**3. Kibana `JavaScript heap out of memory` crash loop**

Not CPU-related this time — Kibana 8.19 initializes 172 plugins on startup, and Node.js's auto-sized heap (based on the container's memory limit) wasn't enough to get through that without crashing. Fixed by raising Kibana's container memory limit and explicitly setting `NODE_OPTIONS=--max-old-space-size=1024` rather than relying on Node's auto-detection.

## Why it's not staying up

Between Elasticsearch's heap and Kibana's heap, this pushed total memory usage close to the ceiling of what's actually free on this box alongside the rest of the stack (see [Architecture and Hardware](Architecture-and-Hardware.md)) — workable for a lab session, not something worth running 24/7 next to a monitoring stack that already does the job. The compose file stays in this repo as a reference for re-running the lab, not as an always-on service.

## Lessons learned

- "Modern ELK" today means Elastic Agent + Fleet integrations replacing individually-configured Beats — worth knowing conceptually even without a permanently running deployment to point at.
- Docker image base-OS changes can silently raise the minimum CPU generation required, independent of anything in your own compose file — this will likely resurface on other images down the line on this hardware, not just Elasticsearch.
- Default resource auto-detection (Node.js heap sizing, in this case) doesn't always get it right inside a memory-constrained container — explicit sizing beats trusting the default when things are already tight.

[← Back to Home](Home.md)
