# Lessons Learned

Things that weren't obvious until running this in practice.

## Secrets hide in more places than `.env` files

The first pass at redacting this repo before publishing only grepped for text patterns like `password` and `token`. That missed real secrets sitting in `config/` directories — a JWT signing key in Filebrowser's `settings.json`, API keys in the *arr apps' `config.xml` files. The fix was to gitignore entire `config/` and `data/` directories by convention, rather than trying to catch every secret individually with a text search.

## Splitting Compose stacks per service pays off

One Compose file per service (instead of one big file for everything) made it possible to update, restart, or debug a single service without touching the rest of the stack — and made the git history for this repo readable, since each commit maps to one logical piece of infrastructure.

## Monitoring from day one, not after something breaks

Standing up Prometheus + Grafana + cAdvisor + node-exporter early, before anything went wrong, meant resource pressure showed up on a dashboard instead of as an unexplained outage. On modest hardware this matters more, not less.

## Disk health monitoring is cheap insurance

Hard Disk Sentinel running continuously catches degrading drives via S.M.A.R.T. data well before failure — reallocated sectors and rising temperatures are visible weeks or months ahead of an actual crash.

## K3s: RBAC gaps look like a wall of errors, not one clear message

`kube-state-metrics`'s bundled ClusterRole doesn't cover every resource type it tries to watch — `NetworkPolicy`, `MutatingWebhookConfiguration`, `ValidatingWebhookConfiguration` were all missing here. The symptom wasn't one obvious permissions error; it was a continuous stream of `reflector.go` `Failed to list ... is forbidden` lines, one per resource type, repeating every reconcile loop. The fix was a supplementary `ClusterRole` + `ClusterRoleBinding` granting just the missing `list`/`watch` verbs, applied alongside the chart's own RBAC rather than replacing it.

Two things weren't obvious the first time through:

- **Widening the RBAC grant isn't enough on its own.** The running pod's informers had already failed and cached that failure state — they don't retry against newly-granted permissions automatically. `kubectl rollout restart deployment kube-state-metrics -n monitoring` was required before the fix actually took effect.
- **Old errors don't vanish from Grafana the moment a fix ships.** Loki keeps every line it already ingested; a dashboard's "Errors" panel only reflects what falls inside its time window (e.g. "Last 1 hour"). Right after the restart the panel still showed the old forbidden-access errors, which briefly looked like the fix hadn't worked — it had. Checking `kubectl logs <new-pod> --since=<pod-age>` directly, and watching the panel's error *total* trend downward over a few minutes, confirmed it rather than expecting an instant clean slate.

## Not every WARN/ERROR line is worth alerting on

Two log patterns showed up constantly on the K3s log dashboard without indicating an actual problem: CoreDNS logging a `WARN` every time it globs for an optional custom-config file that doesn't exist, and `kube-state-metrics` logging a `v1 Endpoints is deprecated` notice ahead of a future Kubernetes API removal. Neither needed a cluster-side fix — the dashboard's LogQL queries got a `!~` (negative-match) exclusion for both known-benign patterns instead, so the Errors/Warnings panels reflect things actually worth investigating.

## What's next

- Self-hosted Gitea for private repos and CI runners
- Automated deployment via Watchtower on new image pushes
- Alerting rules on top of the existing Prometheus/Grafana setup, not just dashboards
