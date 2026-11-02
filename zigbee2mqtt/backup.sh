set -eu
while true; do
  sleep 600
  test -f /app/data/.initialized
  for file in database.db state.json coordinator_backup.json configuration.yaml; do
    aws --endpoint-url="$AWS_ENDPOINT" s3 cp "/app/data/$file" "s3://$BUCKET/$file"
  done
done
