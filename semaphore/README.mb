# AWX Installation Journey (Abandoned in Favor of Semaphore)

## Overview

One of my goals for my homelab was learning **Ansible AWX**, the open-source upstream project of Red Hat Ansible Automation Platform.

Initially I wanted to deploy AWX entirely with Docker since the rest of my homelab is containerized.

During this project I discovered that AWX has completely moved away from Docker Compose deployments and now officially targets Kubernetes via the AWX Operator.

Rather than continue patching an obsolete deployment method, I decided to document the investigation and switch to **Semaphore**, which better matches my current Docker-based homelab.

---

# Environment

- Ubuntu 24.04 LTS
- Docker Engine
- Docker Compose v2
- Ansible Core 2.16
- Git
- GNU Make

---

# Attempt 1 – Community Repository

I first cloned:

```bash
git clone https://github.com/fitbeard/ansible-platform.git
```

After exploring the project, I realized it was **not a Docker deployment of AWX**.

Instead it deploys:

- AWX Operator
- Automation Platform components
- Kubernetes resources

This was abandoned because my goal was running AWX directly in Docker.

---

# Attempt 2 – Official AWX Repository

I cloned the official project:

```bash
git clone https://github.com/ansible/awx.git
```

Checked out the latest stable release:

```bash
git checkout 24.6.1
```

The repository still contains:

```
tools/docker-compose/
```

which initially appeared to support Docker deployments.

---

# Docker Compose Preparation

Verified:

- Docker
- Docker Compose
- Make
- Python
- Ansible

All prerequisites were already installed.

---

# Issue 1 – Broken docker-compose Binary

My machine still had an old legacy binary:

```
/usr/local/bin/docker-compose
```

Running:

```bash
docker-compose version
```

returned:

```
Not: not found
```

After inspecting the AWX Makefile, I confirmed it actually uses:

```
docker compose
```

instead of the old standalone binary.

Removing the obsolete binary fixed this issue.

---

# Issue 2 – Ansible Galaxy Blocked

Running:

```bash
make docker-compose
```

failed with:

```
403 Forbidden
```

against:

```
https://galaxy.ansible.com
```

This appears to be due to regional sanctions.

Fortunately the repository already contained the required collection archives.

Installed manually:

```bash
ansible-galaxy collection install awx-awx-24.6.1.tar.gz

ansible-galaxy collection install community-docker-5.2.1.tar.gz

ansible-galaxy collection install flowerysong-hvault-0.3.0.tar.gz
```

After installation I skipped the Galaxy download step.

---

# Issue 3 – Quay.io Blocked

The next failure occurred while Docker attempted to pull:

```
quay.io/sclorg/postgresql-15-c9s
```

The registry returned:

```
403 Forbidden
```

Testing Quay directly confirmed the registry was inaccessible from my location.

To continue testing, I modified the generated compose file to use:

```yaml
image: postgres:15
```

and updated the PostgreSQL environment variables accordingly.

---

# Issue 4 – Missing AWX Development Image

The final blocker was:

```
ghcr.io/ansible/awx_devel:HEAD
```

Docker returned:

```
manifest unknown
```

Investigation showed that:

- `awx_devel` is a development image
- versioned tags are no longer published
- the Docker Compose workflow expects developers to build the image locally

using:

```bash
make docker-compose-build
```

rather than pulling a stable image.

---

# Conclusion

At this point it became clear that the Docker Compose deployment is no longer intended as a supported installation method.

Instead it exists only as a development environment for AWX contributors.

The officially supported installation method today is:

```
Kubernetes
    ↓
AWX Operator
    ↓
AWX
```

---

# Decision

Rather than continue patching an obsolete deployment, I decided to stop the project.

For my Docker-based homelab I installed **Semaphore** instead.

Semaphore provides:

- Web UI
- Playbook execution
- Inventories
- SSH key management
- Scheduling
- Templates

while remaining simple to deploy with Docker Compose.

---

# Lessons Learned

This project was still valuable because it reinforced several important DevOps skills:

- Reading project documentation
- Inspecting Makefiles
- Understanding Ansible collections
- Troubleshooting Docker image registries
- Working around regional network restrictions
- Understanding the evolution of deployment methods
- Recognizing when to stop patching legacy software and adopt the supported architecture instead

---

# Future Plans

In the future I plan to learn Kubernetes properly.

Once comfortable with Kubernetes, I intend to deploy AWX using the officially supported AWX Operator.

```
Ubuntu
    ↓
Docker
    ↓
k3s
    ↓
Helm
    ↓
AWX Operator
    ↓
AWX
```

Until then, Semaphore satisfies my automation needs while allowing me to continue learning Ansible.