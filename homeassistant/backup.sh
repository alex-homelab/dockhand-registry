set -eu
umask 077
if ! command -v tar >/dev/null 2>&1 || ! command -v gzip >/dev/null 2>&1; then
  yum install -y tar gzip >/dev/null
fi
work=$(mktemp -d /tmp/ha-backup.XXXXXX)
trap 'rm -rf "$work"' EXIT
backup_once() {
  test -f /config/.initialized
  test -f /config/configuration.yaml
  rc=0
  tar --exclude='config/home-assistant_v2.db*' --exclude='*.log*' --exclude='config/backups' --exclude='config/.initialized' -czf "$work/backup.tgz" -C / config || rc=$?
  # GNU tar exit 1 means files changed while HA was running; validate before upload.
  # Exit 2 or higher is a real failure and must never replace the R2 archive.
  if [ "$rc" -gt 1 ]; then
    echo "HA archive creation failed (tar exit $rc)" >&2
    return "$rc"
  fi
  tar -tzf "$work/backup.tgz" > "$work/members"
  grep -qx 'config/configuration.yaml' "$work/members"
  aws --endpoint-url="$AWS_ENDPOINT" s3 cp "$work/backup.tgz" "s3://$BUCKET/backup.tgz" --only-show-errors
  local_size=$(wc -c < "$work/backup.tgz" | tr -d ' ')
  remote_size=$(aws --endpoint-url="$AWS_ENDPOINT" s3api head-object --bucket "$BUCKET" --key backup.tgz --query ContentLength --output text)
  test "$local_size" = "$remote_size"
  printf '%s HA config backup uploaded and verified: %s bytes\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$remote_size"
}
if [ "${BACKUP_ONCE:-0}" = 1 ]; then
  backup_once
else
  while true; do
    sleep "${BACKUP_INTERVAL_SECONDS:-300}"
    backup_once
  done
fi
