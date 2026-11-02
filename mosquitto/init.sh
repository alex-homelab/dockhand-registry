set -eu
if [ ! -f /config/.initialized ]; then
  printf '%s' "$CONFIG_B64" | base64 -d > /config/mosquitto.conf
  printf '%s' "$MOSQUITTO_PASSWORD_B64" | base64 -d > /config/password.txt
  chmod 600 /config/password.txt
  chown -R 1883:1883 /config
  touch /config/.initialized
fi
