set -eu
yum install -y tar gzip >/dev/null
while true; do
  sleep 300
  test -f /config/.initialized
  tar --exclude='config/home-assistant_v2.db*' --exclude='*.log*' --exclude='config/backups' --exclude='config/.initialized' -czf /tmp/backup.tgz -C / config
  aws --endpoint-url="$AWS_ENDPOINT" s3 cp /tmp/backup.tgz "s3://$BUCKET/backup.tgz"
done
