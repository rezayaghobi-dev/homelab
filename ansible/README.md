# Ansible

Two playbooks families live here: one for **updating** Docker Compose stacks day-to-day, and one for **provisioning** a fresh server from scratch. Both are designed to run through [Semaphore](../docs/Semaphore.md).

## Directory structure

```
ansible/
├── update-playbooks/              # day-to-day Docker Compose stack updates
│   ├── roles/
│   │   └── docker_compose_update/
│   │       ├── defaults/          # role defaults (currently empty — vars come from playbooks)
│   │       └── tasks/
│   │           └── main.yml       # shared pull → recreate → health-check → prune logic
│   ├── ping.yml                   # connectivity check
│   ├── update-agent-canvas.yml
│   ├── update-filebrowser.yml
│   ├── update-grafana.yml
│   ├── update-n8n.yml
│   ├── update-npm.yml
│   ├── update-pihole.yml
│   ├── update-plex.yml
│   ├── update-portainer.yml
│   ├── update-prowlarr.yml
│   ├── update-radarr.yml
│   ├── update-samba.yml
│   ├── update-sentinel.yml
│   ├── update-smartctl.yml
│   ├── update-sonarr.yml
│   └── update-whisparr.yml
│
└── preparing-playbook/            # one-time server provisioning (learning lab / Vagrant testing)
    └── reza-ansible/
        ├── ansible.cfg
        ├── preparing.yaml         # playbook: harden + Docker install
        ├── repo-server.yaml       # playbook: Nexus + Traefik repo server
        ├── .vault.pass            # ⚠️  gitignored — must be created locally
        ├── inventory/
        │   ├── host.yaml          # inventory — hosts and connection details
        │   ├── group_vars/
        │   │   └── all/
        │   │       ├── preparing.yaml   # packages, sshd, iptables, sysctl, auditd
        │   │       ├── docker.yaml      # Docker daemon config (proxy, registry mirror)
        │   │       ├── proxy.yaml       # HTTP proxy credentials
        │   │       ├── repo-server.yaml # Nexus/Traefik/domain config
        │   │       ├── backup.yaml      # backup volume/path config
        │   │       └── vault.yaml       # 🔒 Ansible Vault encrypted secrets
        │   └── host_vars/
        │       └── vagrant-test.yaml    # Vagrant-specific overrides
        └── roles/
            ├── preparing_server/        # packages, sshd, iptables, fail2ban, auditd, lynis, sysctl
            ├── docker/                  # Docker CE + Compose plugin install + daemon config
            └── repo-server/             # Nexus3 + Traefik + Docker registry setup
```

## update-playbooks — how it works

Every always-on Docker Compose stack has a thin playbook that delegates to the shared `docker_compose_update` role. Each playbook is intentionally minimal:

```yaml
---
- hosts: all
  become: true
  vars:
    compose_dir: "/home/rezayaghobi/docker/<service>"
    service_name: "<Friendly Name>"
  roles:
    - docker_compose_update
```

The shared role runs the same sequence for every stack:

1. **Records start time** for a duration summary
2. **Snapshots `docker system df`** before the pull
3. **Runs `docker compose pull`** in the stack's directory
4. **Snapshots `docker system df`** again — before/after comparison catches unexpectedly large pulls
5. **Runs `docker compose up -d`** to recreate containers with new images
6. **Waits 5 seconds**, then checks `docker compose ps`
7. **Asserts every container is up** — fails the run (and skips cleanup) if anything shows `Exit`, `Created`, or `Restarting`
8. **Runs `docker image prune -f`** to reclaim space — only if the health check passed
9. **Prints a summary** — duration, cleanup result, pass/fail

If any step fails, Ansible stops immediately rather than continuing to prune images out from under a broken deployment.

### Adding a new stack

Copy any existing playbook, change `compose_dir` and `service_name`. No changes to the role itself.

## preparing-playbook — server provisioning

A full server preparation pipeline for fresh Ubuntu/Debian installs, designed for testing against the Vagrant VM before running on real hardware.

### `preparing.yaml`

Runs two roles in sequence:

1. **`preparing_server`** — installs base packages, configures sshd, sets up iptables rules, enables fail2ban, configures auditd, tunes sysctl, installs lynis for security auditing
2. **`docker`** — installs Docker CE + Compose plugin from Docker's official repo, configures daemon with proxy/mirror settings

### `repo-server.yaml`

Runs the **`repo-server`** role — pulls Nexus3, Traefik, and supporting images, then configures and starts them as a self-hosted artifact repository with TLS via Traefik.

### Inventory

- `inventory/host.yaml` — defines the `repo-servers` group (currently just `vagrant-test` on `127.0.0.1:2222`)
- `inventory/group_vars/all/` — shared variables for all hosts
- `inventory/host_vars/vagrant-test.yaml` — Vagrant-specific overrides (sshd port, iptables trusted ranges)

### Running locally against Vagrant

```bash
cd ansible/preparing-playbook/reza-ansible

# provision the server (packages + hardening + Docker)
ansible-playbook preparing.yaml -i inventory/host.yaml

# set up the repo server (Nexus + Traefik)
ansible-playbook repo-server.yaml -i inventory/host.yaml

# connectivity check only
ansible all -m ping -i inventory/host.yaml
```

## ⚠️ Before pushing to GitHub

The `preparing-playbook/` contains hardcoded credentials and personal infrastructure details that must be sanitized before making this repo public:

| File | Contains | What to do |
|---|---|---|
| `.vault.pass` | Plaintext vault password | Already in `.gitignore` — must be recreated locally |
| `group_vars/all/vault.yaml` | Encrypted secrets | Safe to commit (Ansible Vault encrypted) |
| `group_vars/all/proxy.yaml` | Proxy username + password in plaintext | Move credentials to `vault.yaml`, reference as `{{ vault_proxy_user }}:{{ vault_proxy_pass }}` |
| `group_vars/all/docker.yaml` | Proxy IP, registry mirror URL | Replace with `{{ vault_docker_proxy }}` / `{{ vault_registry_mirror }}` |
| `group_vars/all/preparing.yaml` | Trusted IP addresses | Replace with `{{ vault_trusted_ips }}` |
| `group_vars/all/repo-server.yaml` | Domain name, emails, usernames | Replace with vault variables |
| `inventory/host.yaml` | SSH key file path | Replace with `{{ vault_ssh_key_path }}` or a generic path |

The **update-playbooks/** are safe as-is — they only contain `compose_dir` paths with the local username and `service_name` labels.

## Running via Semaphore

Both playbook families are executed through [Semaphore](../docs/Semaphore.md) — no manual `ansible-playbook` on the server. Each playbook is set up as a Task Template pointed at this repo. See [Ansible Playbooks](../docs/AnsiblePlaybooks.md) for the full workflow and the [Semaphore Guide](../docs/Semaphore.md) for setup details.

[← Back to Home](../docs/Home.md)
