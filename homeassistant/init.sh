set -eu
yum install -y tar gzip >/dev/null
if [ ! -f /config/.initialized ]; then
  aws --endpoint-url="$AWS_ENDPOINT" s3 cp "s3://$BUCKET/backup.tgz" /tmp/backup.tgz
  tar -xzf /tmp/backup.tgz -C / config
  test -f /config/configuration.yaml
  touch /config/.initialized
fi
# Preserve the restored YAML; add only current proxy peers and gw itself.
# Recheck these /32 addresses if NetBird replaces its proxy peers.
grep -q '^  trusted_proxies:$' /config/configuration.yaml
for proxy in 100.71.109.63/32 100.71.222.49/32 100.71.86.199/32; do
  if ! grep -Fq "$proxy" /config/configuration.yaml; then
    sed -i "/^  trusted_proxies:$/a\\    - $proxy" /config/configuration.yaml
  fi
done
