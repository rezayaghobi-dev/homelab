# Preview run doc

## Mode

Standalone HTML file — no dev server, no dependencies.

## How to reproduce

1. The preview is a single static file at `.freebuff/preview.html`
2. No build step, no install — just open it in a browser or register it via `register_preview` with `htmlPath`

## Running

```bash
# The preview is served by Freebuff's built-in static file server.
# No manual server needed — just point register_preview at the HTML file.
```

To re-register:
```
register_preview(htmlPath="D:\\files\\projects\\homelab\\docker-compose\\.freebuff\\preview.html")
```
