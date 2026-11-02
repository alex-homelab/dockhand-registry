set -eu
if [ ! -f /app/data/.initialized ]; then
  for file in database.db state.json coordinator_backup.json; do
    aws --endpoint-url="$AWS_ENDPOINT" s3 cp "s3://$BUCKET/$file" "/app/data/$file"
  done
  if ! aws --endpoint-url="$AWS_ENDPOINT" s3 cp "s3://$BUCKET/configuration.yaml" /app/data/configuration.yaml; then
    printf '%s' "$CONFIG_B64" | base64 -d > /app/data/configuration.yaml
  fi
  touch /app/data/.initialized
fi
