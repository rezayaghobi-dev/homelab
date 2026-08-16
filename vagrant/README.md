# Vagrant Test VM

A disposable VirtualBox VM for trying out provisioning scripts and configuration changes before running them against the real host — mistakes here cost a `vagrant destroy`, not a broken production service.

## What it creates

- **Box:** `bento/debian-12`
- **Hostname:** `test`
- **Network:** private network, static IP `192.168.56.10` — reachable from the host but isolated from the rest of the LAN
- **Resources:** 1 vCPU, 1024 MB RAM — enough to exercise a bootstrap script or a small playbook run, not meant to run real workloads

## Usage

```bash
vagrant up          # create and provision the VM
vagrant ssh          # log in
vagrant provision    # re-run bootstrap.sh against a VM that's already up
vagrant destroy      # tear it down completely
```

## `bootstrap.sh`

Runs automatically on `vagrant up` via Vagrant's shell provisioner. Currently:

```bash
apt-get update
sudo apt install -y vim iptables-persistent bash-completion
```

Baseline packages for a usable shell environment — `iptables-persistent` in particular anticipates using this VM to test firewall rule changes without risking the real host's `iptables` state.

## Why this exists

Testing changes directly on the host (or worse, in production containers) means a bad `iptables` rule or a broken package install has real consequences. This VM gives a throwaway Debian environment matching the host's OS family, so provisioning changes — Ansible playbook edits, install scripts, firewall rules — get a dry run first. `vagrant destroy && vagrant up` resets to a clean slate in a couple of minutes.
