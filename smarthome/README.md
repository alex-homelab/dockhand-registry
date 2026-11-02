# Smarthome stacks

## Status (2026-11-02)

- Dockhand Git stack `mosquitto` (ID 7) is running on gw. MQTT: 100.71.86.199:1883; WebSockets: 100.71.86.199:9001.
- Dockhand Git stack `zigbee2mqtt` (ID 8) is running on gw. UI: http://100.71.86.199:8080 and https://z2m.vcov.org. Existing NetBird authentication and access restrictions were preserved.
- Both stacks deploy main from this repository and sync daily at 03:00. Their Compose context directories include init.sh and backup.sh.
- Kubernetes Deployment/zigbee2mqtt in namespace smarthome is scaled to zero. The committed legacy-zigbee2mqtt-patch.yaml records this state; the original deployment had no Argo CD ownership labels.
- Kubernetes Mosquitto remains running as a compatibility broker because Home Assistant still connects to 192.168.1.163:1883. The Docker broker has an authenticated bidirectional bridge to that endpoint. Do not stop the legacy broker until HA and any other clients are migrated.
- Home Assistant stack (ID 9) is staged, not deployed; its Kubernetes instance remains online.

## Secrets

For the two deployed stacks, secretProviderId is null and secrets are protected environment variables in Dockhand, copied directly from Kubernetes without displaying or committing values. This temporary fallback avoids the Infisical HTTP-client block. The Home Assistant stack still binds the Infisical provider and is not activated.

Mosquitto: CONFIG_B64 contains the original mosquitto-config/mosquitto.conf plus the temporary compatibility bridge settings. MOSQUITTO_PASSWORD_B64 contains the original mosquitto-password/password.txt. The config and password files are rendered only into the persistent config volume. Never commit either decoded file.

Zigbee2MQTT: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ENDPOINT, AWS_REGION and BUCKET come from r2-credentials. CONFIG_B64 comes from zigbee2mqtt-config/configuration.yaml. MQTT_USER/MQTT_PASSWORD come from mqtt-credentials. MQTT_SECRET_B64 contains JSON-compatible YAML for secret.yaml, required by the restored configuration's secret references. MQTT server is mqtt://mosquitto:1883.

Future Infisical paths: /mosquitto, /zigbee2mqtt and /homeassistant. The project/provider uses EU https://eu.infisical.com. Direct Python urllib requests receive Cloudflare 403 with `error code: 1010`, before token validation. Resolve with the service owner; do not repeatedly rotate tokens or evade the block. These new paths have not been provisioned by this change.

## Data and backups

Images are pinned to the original Kubernetes image digests. Named Docker volumes replace emptyDir. One-shot init must succeed before the app starts; `.initialized` prevents re-restoring over initialized data.

Zigbee2MQTT restores database.db, state.json, coordinator_backup.json and configuration.yaml from the original R2 bucket. ConfigMap fallback applies only when configuration.yaml download fails; successful downloads are not overwritten. secret.yaml is rendered from protected Dockhand data on init. The backup sidecar uploads the four original object keys every 600 seconds, mounting data read-only. Errors exit and Docker restarts the sidecar. At cutover the old node process was paused, final files uploaded to R2 and a validated private tar archive saved on gw, then the old pod was deleted before starting Docker Zigbee2MQTT. R2 restore completed successfully. A manual upload through the running Docker backup container and HEAD verification of all four objects succeeded.

Mosquitto had no R2 backup in Kubernetes. Config/password come from protected Dockhand variables. The original persistence=false setting is preserved. An additional volume exists at /mosquitto/data if persistence is enabled later.

Home Assistant (not activated) restores config/ from backup.tgz and uploads every 300 seconds, excluding recorder SQLite, logs and nested backups as in Kubernetes. This is config-only backup, not recorder history. tar/gzip install follows the original AWS CLI containers.

## Network and compatibility

Shared Docker network: shared-services. All published ports bind only 100.71.86.199.

NetBird Home resources/policies:
- Coordinator: 192.168.1.1/32, resource dbk9is2fadhs738a46cg, policy dbk9isafadhs738a46f0 permits only gw/Contabo TCP 20108.
- Temporary MQTT bridge: 192.168.1.163/32, policy Contabo MQTT bridge permits only gw/Contabo TCP 1883.

Both endpoints were verified from gw; coordinator TCP was also verified from Docker. Home currently routes through MacBook-Pro-Aleksandr.local (100.71.244.61), while NAS is offline. Keep a routing peer online or provide an always-on replacement.

Verified: Zigbee2MQTT startup/coordinator connection, frontend HTTP 200, authenticated read-only MQTT subscriptions report bridge/state online on both new and old brokers, R2 uploads and object metadata. No physical-device commands were issued as a test.

## Remaining Home Assistant cutover

Kubernetes HA uses home-node hostNetwork. The staged VPS Compose binds NetBird through bridge networking; LAN multicast discovery, Bluetooth, local devices and Matter connectivity do not transfer automatically. Decide network placement and update HA MQTT/Matter endpoints through supported settings before activation. Stop its old R2 writer before enabling the Docker writer; original bucket/key locations are shared. Keep Kubernetes data and private backups for rollback.
