\# Semaphore



\*\*Semaphore\*\* is a modern, lightweight, open-source web UI for Ansible. It serves as a practical self-hosted alternative to AWX (Ansible Tower) for running playbooks, managing inventories, SSH keys, schedules, and execution logs.



It was chosen for this homelab because:

\- Much lighter on resources than AWX + Kubernetes

\- Simple Docker Compose deployment

\- Actively maintained

\- Perfect fit for learning Ansible in a Docker-based environment



\## Access



\- \*\*Friendly URL\*\*: `https://semaphore.home` (via Nginx Proxy Manager + mkcert)

\- \*\*Direct\*\*: `http://192.168.100.6:3001`



\*\*Initial Login\*\* (change password immediately after first login):

\- Username / Email: `admin` or `rezay5639@gmail.com`

\- Password: `rezayaghobi1386`



\## Features Currently Used



\- Run Ansible playbooks

\- Manage inventories (static + dynamic)

\- Store and use SSH keys securely

\- Schedule recurring tasks

\- View detailed execution logs

\- User \& team management



\## Local Setup



```bash

cd \~/docker/semaphore

docker compose up -d

