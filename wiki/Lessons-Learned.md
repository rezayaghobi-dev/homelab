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

## What's next

- Self-hosted Gitea for private repos and CI runners
- Automated deployment via Watchtower on new image pushes
- Alerting rules on top of the existing Prometheus/Grafana setup, not just dashboards
