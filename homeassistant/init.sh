set -eu
yum install -y tar gzip >/dev/null
if [ ! -f /config/.initialized ]; then
  aws --endpoint-url="$AWS_ENDPOINT" s3 cp "s3://$BUCKET/backup.tgz" /tmp/backup.tgz
  tar -xzf /tmp/backup.tgz -C / config
  test -f /config/configuration.yaml
  touch /config/.initialized
fi
