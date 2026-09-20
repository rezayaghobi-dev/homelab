# Argo CD Application Manifests

This folder holds the **Argo CD `Application` objects** — the manifests that tell Argo CD which Git path to watch and which cluster/namespace to deploy into. Each subfolder corresponds to one app, matching the name used under [`../apps/`](../apps/README.md):

```
kubernetes/argocd-apps/
├── README.md              ← you are here
├── homepage/
│   └── homepage-app.yaml
└── <name>/
    └── <name>-app.yaml
```

## What lives here

- **One `Application` YAML per app**, named `<name>-app.yaml`. This is the Argo CD control plane entry point — it sets the source repo, target revision, git `path`, destination server and namespace, and sync policy (automated with `prune` and `selfHeal`).

Example (from `homepage/homepage-app.yaml`):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: homepage
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/rezayaghobi-dev/homelab
    targetRevision: main
    path: kubernetes/apps/homepage
  destination:
    server: https://kubernetes.default.svc
    namespace: homepage
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## What does *not* live here

- **Workload manifests** (`Deployment`, `Service`, `Ingress`, etc.). Those live in the sibling [`../apps/`](../apps/README.md) folder. This separation is deliberate: Argo CD should never watch its own `Application` definitions, otherwise a recursive sync loop becomes possible.

## Why this separation matters

Keeping "what tells Argo CD to run" (`<name>-app.yaml`) and "what actually runs" (the manifests in `../apps/<name>/`) in different folders means:

- **No accidental self-watch.** Argo CD watches `kubernetes/apps/`, not `kubernetes/argocd-apps/`. An Application manifest changing its own `path` would have no effect — it'd be out of the watched tree entirely.
- **Independent lifecycle.** The Application object is applied once via `kubectl`; everything after that — the Deployments, Services, Ingresses it ultimately creates — flows from git through Argo CD's reconciliation loop.
- **One job per file.** Adding an app means adding one file here (the Application) and one directory there (the manifests). Easy to audit, easy to delete.

## Applying a new Application

After creating `kubernetes/argocd-apps/<name>/<name>-app.yaml`, apply it once:

```bash
kubectl apply -f kubernetes/argocd-apps/<name>/<name>-app.yaml
```

Argo CD picks it up immediately, creates the app in its UI, and begins syncing. After this single `kubectl` call, **all** future changes flow through git — modifying the Application manifest itself is rarely needed once it's running.

## Relationship to the rest of the repo

The folder structure mirrors [`../apps/`](../apps/README.md) one-to-one: each app under `kubernetes/argocd-apps/` has a matching folder under `kubernetes/apps/`. This isn't strictly enforced by Argo CD, but keeping the two trees parallel makes it trivial to trace "which Application watches which manifests."

[← Back to Home](../../docs/Home.md)
