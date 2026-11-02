# Smarthome stacks

## Current state (2026-11-02)

- `mosquitto`, Dockhand stack 7: running on gw, MQTT 100.71.86.199:1883 and WebSockets :9001.
- `zigbee2mqtt`, stack 8: running on gw, http://100.71.86.199:8080 and https://z2m.vcov.org. Its old Kubernetes Deployment is scaled to zero. Coordinator startup and 25 joined devices were confirmed.
- `homeassistant`, stack 9: active trial of latest stable 2026.10.4 on gw, with R2 init and NO backup service. Automatic Git sync remains disabled for this trial. Kubernetes Home Assistant is temporarily scaled to zero. See [trial findings and rollback](../homeassistant/TRIAL.md).
- Kubernetes Mosquitto remains running because HA still uses 192.168.1.163:1883. Docker Mosquitto has an authenticated bidirectional bridge to that broker. Do not stop it until all clients are migrated.
- Kubernetes Matter remains running and is reachable by Docker HA using the existing service address and a narrow NetBird policy.

All apps are Git stacks from this repository with per-stack context directories. Mosquitto and Zigbee2MQTT sync daily at 03:00. Published ports bind only the NetBird address. Legacy replica-zero patches are recorded in this directory; these original Deployments had no Argo CD ownership labels.

## Secret storage

The active stacks currently use protected Dockhand environment variables copied directly from Kubernetes; secretProviderId is null. No secret values are committed. EU Infisical https://eu.infisical.com blocks direct Python urllib requests with Cloudflare 1010 before token validation. This temporary fallback avoids putting credentials in Git; resolve the client block with the service owner before moving the variables to Infisical.

- Mosquitto: CONFIG_B64 contains the original config plus compatibility bridge; MOSQUITTO_PASSWORD_B64 contains the original password hash file.
- Zigbee2MQTT: R2 variables from r2-credentials; CONFIG_B64 from zigbee2mqtt-config; MQTT_USER/MQTT_PASSWORD from mqtt-credentials; MQTT_SECRET_B64 renders the secret.yaml referenced by restored configuration. MQTT server is mqtt://mosquitto:1883.
- HA: R2 variables from r2-credentials-ha. Init also adjusts exact trusted proxy addresses in the migrated HTTP store, offline before startup; details are in TRIAL.md.

## Restore and backup

Pinned original image digests are used for Mosquitto/Zigbee2MQTT. HA is explicitly tagged 2026.10.4. Persistent named volumes replace emptyDir; one-shot init must complete before the app starts. `.initialized` prevents overwriting initialized data on subsequent deploys.

Zigbee2MQTT restores database.db, state.json, coordinator_backup.json and configuration.yaml from R2. ConfigMap fallback is used only if configuration.yaml download fails. secret.yaml is rendered privately on init. Its read-only-volume backup sidecar uploads those four keys every 600 seconds; upload failure exits and Docker restarts the sidecar. At cutover the source process was paused, final files uploaded and privately archived, then the old pod was deleted before Docker startup. Docker restore, uploads and HEAD verification of all four R2 objects succeeded.

Mosquitto had no R2 backup sidecar in Kubernetes. Its original persistence=false setting is retained; config/password are protected variables and persistent files. A data volume exists if persistence is enabled later.

HA init restores config/ from backup.tgz. Existing R2 archives exclude recorder SQLite, logs and nested backups. The trial has NO backup service, so its configuration changes are not written to R2. Before source shutdown a validated config archive and consistent recorder SQLite backup were saved privately for rollback. The retained homeassistant/backup.sh is not referenced by the trial Compose file.

## Home routing

- Coordinator 192.168.1.1/32: resource dbk9is2fadhs738a46cg, policy dbk9isafadhs738a46f0 permits only gw/Contabo TCP 20108.
- Legacy MQTT 192.168.1.163/32: policy Contabo MQTT bridge permits only gw/Contabo TCP 1883.
- Existing Matter resource 10.43.17.129/32: policy Contabo Matter service permits only gw/Contabo TCP 5580; Compose maps matter-server to this address.

Coordinator and Matter connectivity were checked from Docker. Home routing currently depends on MacBook-Pro-Aleksandr.local, while NAS is offline; keep a Home routing peer online. Moving HA from a home-node host network to a VPS bridge does not automatically carry LAN discovery, multicast, Bluetooth or all local integrations. Moonraker at 192.168.1.134:7125 needs separate LAN access.

MQTT state was verified online on both bridged brokers. No physical-device command was issued as a test. Keep original Kubernetes manifests/data and private backups for rollback. Stop Docker HA before reactivating the Kubernetes instance; do not run two HA automation engines or two Zigbee2MQTT controllers concurrently.
