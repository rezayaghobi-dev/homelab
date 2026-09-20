# Kubernetes Apps

This folder holds the actual Kubernetes workload manifests for every app managed via Argo CD's GitOps flow. Each subfolder is one application, named after the app itself:

```
kubernetes/apps/
├── README.md              ← you are here
├── homepage/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
├── <name>/                 ← new apps go here
│   ├── ...
│   └── kustomization.yaml
```

## What lives here

- **Workload manifests** — `Deployment`, `Service`, `ConfigMap`, `Ingress`, `Secret`, etc. These describe the pods, networking, and config that Argo CD applies to the cluster.
- **`kustomization.yaml`** — the Kustomize entry point for the app. Argo CD watches the path this file declares, so every app folder must include one and list every sibling manifest under `resources:`.

These are the files that end up running in the cluster. This is "what runs."

## What does *not* live here

- **Argo CD `Application` objects.** Those live in the sibling [`../argocd-apps/`](../argocd-apps/README.md) folder, deliberately kept separate so Argo CD never watches its own definitions.
- **Namespace-scoped governance objects.** The cluster-level `LimitRange` and `ResourceQuota` live in [`../resource-limits/`](../resource-limits/resource-limits.yaml), applied once at cluster setup rather than per-app.

## Relationship to the rest of the repo

Every always-on Docker Compose service in this repo (see [`docker-compose/`](../../docker-compose/)) has a self-contained folder with its own `docker-compose.yml`. The Kubernetes side mirrors that convention — one folder per app, fully self-contained — so the structure on both sides is parallel and easy to navigate.

## Adding a new app

See [ArgoCD](docs/argocd.md#adding-a-new-app) for the full walkthrough. In short:

1. Create `kubernetes/apps/<name>/` with manifests + `kustomization.yaml`.
2. Create the matching `kubernetes/argocd-apps/<name>/<name>-app.yaml` Application manifest pointing at that path.
3. `kubectl apply` the Application once — future changes flow through git.

[← Back to Home](../../docs/Home.md)
