# linux_setup.sh

A single idempotent Bash script that takes a fresh Debian/Ubuntu or RHEL/Fedora/CentOS install and prepares it for development work — essential packages, Python, SSH (server + keypair), Docker, common CLI tools, and a few sane baseline system settings.

Written after doing this setup manually one too many times across VMs and fresh installs — this is meant to be the one command that gets a box from "just installed" to "ready to work on" in a couple of minutes.

## What it does

| Step | Installs / Configures |
|---|---|
| **Essential packages** | `curl`, `wget`, `git`, `vim`, `htop`, `jq`, `tar`, `gzip`, `unzip`, build tools, `ca-certificates`, `gnupg` |
| **Python** | Python 3, `pip` (upgraded), `venv`, `virtualenv`, `pipenv` |
| **SSH** | OpenSSH client + server, enabled and started via `systemctl`, `~/.ssh` created with `700` permissions |
| **SSH key** | Generates an `ed25519` keypair (`~/.ssh/id_ed25519`) if one doesn't already exist, prints the public key at the end for easy copying into GitHub/GitLab |
| **Docker** | Docker CE, CLI, containerd, Buildx and Compose plugins from Docker's official repo — verified with a `hello-world` test run after install |
| **Dev tools** | `tree`, `net-tools`, ping utilities, `ncdu`, `btop` |
| **System config** | UTC timezone (if not already set), helpful `ls` aliases in `/etc/bash.bashrc`, basic firewall (UFW or firewalld): deny incoming except SSH, allow all outgoing |

Every step checks whether its target is already installed/configured before doing anything — safe to re-run after a partial failure or to pick up a newly-added tool without redoing the whole setup.

## Supported distributions

Detected automatically via `/etc/os-release` (with fallbacks to `/etc/redhat-release` / `/etc/debian_version`):

- **Debian family** — Debian, Ubuntu, and anything with `ID_LIKE=debian`
- **RHEL family** — RHEL, CentOS, Fedora, and anything with `ID_LIKE` matching `rhel` or `fedora`

Unrecognized distros aren't blocked outright — the script warns and proceeds, but package-manager-specific steps (install, cache update) will no-op rather than guess at a package manager.

## Usage

```bash
sudo ./linux_setup.sh
```

Must run as root (`sudo`) — it's installing system packages, writing to `/etc`, and enabling system services.

### Skip specific steps

```bash
sudo ./linux_setup.sh --skip-docker --skip-dev-tools
```

| Flag | Skips |
|---|---|
| `--skip-packages` | Essential package install + cache update |
| `--skip-python` | Python 3 / pip / virtualenv / pipenv |
| `--skip-ssh` | OpenSSH install + service enable/start |
| `--skip-ssh-key` | SSH keypair generation |
| `--skip-docker` | Docker CE install |
| `--skip-dev-tools` | `tree`, `ncdu`, `btop`, etc. |
| `--skip-system` | Timezone, shell aliases, firewall config |
| `--log-file FILE` | Custom log path (default: `/tmp/linux_setup_<timestamp>.log`) |

Every step is logged to both the terminal (with color-coded `INFO`/`SUCCESS`/`WARNING`/`ERROR` prefixes) and the log file, so a run can be reviewed after the fact without needing to have watched it live.

## Worth knowing before running

- **Firewall is enabled by default** (`--skip-system` to avoid this) — UFW/firewalld gets set to deny all incoming except SSH. Safe for a fresh server, but worth knowing if the box already has other services listening that you don't want cut off.
- **Adds the invoking user to the `docker` group** (Debian family only, via `SUDO_USER`) — meaning that user can run `docker` without `sudo` after their next login. This is the standard Docker convention, but is effectively root-equivalent access to the host, worth being aware of on a shared machine.
- **SSH key has no passphrase** (`-N ""` in the `ssh-keygen` call) — intentional for unattended/scripted setup, but means anyone with filesystem access to `~/.ssh/id_ed25519` can use it directly. Fine for a personal dev box; worth adding a passphrase manually afterward on anything more sensitive.
- Individual step failures are logged as warnings and the script continues rather than aborting — check the log file after a run to confirm nothing silently failed.

## License

MIT (or update to match the rest of the repo's licensing)
