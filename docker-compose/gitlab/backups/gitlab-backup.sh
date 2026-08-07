#!/bin/bash
# GitLab weekly backup — creates a fresh backup, then prunes to keep only
# the single newest copy of each type. Sized for limited free disk space.
#
# Must run as root: GitLab's config/secrets files and data/backups directory
# are owned by root inside the bind-mounted volumes. Ownership of this
# script's own output is handed back to the regular user at the end.
#
# Scheduled via root's crontab:
#   0 2 * * 0 /home/rezayaghobi/backups/run-backup.sh

set -e

TIMESTAMP=$(date +%F)
BACKUP_DIR="/home/rezayaghobi/backups"
GITLAB_DATA_BACKUPS="/home/rezayaghobi/docker/gitlab/data/backups"
LOG_FILE="$BACKUP_DIR/backup.log"

echo "=== Backup started: $(date) ===" >> "$LOG_FILE"

# 1. GitLab's own backup tool (repos, DB, uploads) — does NOT include secrets
docker exec gitlab gitlab-backup create CRON=1 >> "$LOG_FILE" 2>&1

# 2. Config + secrets (gitlab.rb, gitlab-secrets.json, SSH host keys) —
#    root-owned, and not included in gitlab-backup by design. Without this,
#    a restored gitlab-backup archive is unreadable.
tar czf "$BACKUP_DIR/gitlab-config-$TIMESTAMP.tar.gz" /home/rezayaghobi/docker/gitlab/config >> "$LOG_FILE" 2>&1

# 3. Runner config — small, but losing it means re-registering from scratch
tar czf "$BACKUP_DIR/gitlab-runner-config-$TIMESTAMP.tar.gz" /home/rezayaghobi/docker/gitlab/runner-config >> "$LOG_FILE" 2>&1

# 4. Prune: keep only the newest file of each type, delete the rest.
#    Time-based retention (e.g. GitLab's own backup_keep_time) was skipped
#    in favor of this, since a single-copy policy maps more predictably to
#    limited free disk space than a rolling time window would.
find "$GITLAB_DATA_BACKUPS" -name "*_gitlab_backup.tar" -printf '%T@ %p\n' | sort -rn | tail -n +2 | cut -d' ' -f2- | xargs -r rm -f
find "$BACKUP_DIR" -name "gitlab-config-*.tar.gz" -printf '%T@ %p\n' | sort -rn | tail -n +2 | cut -d' ' -f2- | xargs -r rm -f
find "$BACKUP_DIR" -name "gitlab-runner-config-*.tar.gz" -printf '%T@ %p\n' | sort -rn | tail -n +2 | cut -d' ' -f2- | xargs -r rm -f

# 5. Hand ownership back to the regular user — the script ran as root
chown -R rezayaghobi:rezayaghobi "$BACKUP_DIR"

echo "=== Backup finished: $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
