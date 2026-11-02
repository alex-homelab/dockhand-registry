# Smarthome stacks

## Current state (2026-11-02)

- `mosquitto`, Dockhand stack 7: running on gw, MQTT 100.71.86.199:1883 and WebSockets :9001.
- `zigbee2mqtt`, stack 8: running on gw, UI at https://z2m.vcov.org and 100.71.86.199:8080. Its old Kubernetes Deployment is at zero replicas. Coordinator startup and 25 joined devices were confirmed.
- `homeassistant`, stack 9: running on gw at https://ha.vcov.org and 100.71.86.199:8123, version 2026.10.4, with R2 init and configuration backup sidecar every 300 seconds. Kubernetes HA remains at zero replicas. See [trial findings](../homeassistant/TRIAL.md) and [current backup behavior](../homeassistant/BACKUP.md); backups have now been enabled after the user accepted the trial.
- Kubernetes Mosquitto remains as a compatibility broker because HA still uses 192.168.1.163:1883. Docker Mosquitto has an authenticated bidirectional bridge to it. Do not stop it until all clients are migrated.
- Kubernetes Matter remains running and is reachable by Docker HA using the existing service address and a narrow NetBird policy.

Apps are Git stacks from this repository, with per-stack context directories and daily Git sync at 03:00. Published ports bind only the NetBird address. Legacy replica-zero patches are recorded here; the original Deployments had no Argo CD ownership labels.

## Secrets

Active stacks currently use protected Dockhand environment variables copied directly from Kubernetes; secretProviderId is null. EU Infisical blocks direct Python urllib requests with Cloudflare 1010 before token validation. No secret values are committed.

- Mosquitto: CONFIG_B64 contains original config plus compatibility bridge; MOSQUITTO_PASSWORD_B64 contains the password hash file.
- Zigbee2MQTT: R2 variables from r2-credentials; CONFIG_B64 from zigbee2mqtt-config; MQTT_USER/MQTT_PASSWORD from mqtt-credentials; MQTT_SECRET_B64 renders secret.yaml. MQTT server is mqtt://mosquitto:1883.
- HA: R2 variables from r2-credentials-ha. Init adjusts exact trusted proxy addresses in the migrated HTTP store offline; details in TRIAL.md.

## Data and backup writers

Named Docker volumes replace emptyDir. Init must succeed before each app starts; initialized volumes are not overwritten by redeploys.

Zigbee2MQTT restores and backs up database.db, state.json, coordinator_backup.json and configuration.yaml to the original R2 keys every 600 seconds. ConfigMap fallback does not overwrite successful R2 restores. Docker upload and remote object metadata were verified. The old Zigbee2MQTT pod was deleted before Docker startup.

HA restores config/ from backup.tgz and now uploads configuration every 300 seconds. Recorder SQLite, logs and nested backups remain excluded, matching the original scope. Before enabling Docker backups, the previous R2 archive was privately preserved and validated. Details and failure handling are documented in BACKUP.md.

Mosquitto had no R2 backup sidecar in Kubernetes. Its original persistence=false setting is retained; config/password are protected variables and persistent files.

## Routing

[NetBird Home LAN desired configuration and verification](netbird-home-lan.json) records gw access to 192.168.1.0/24. Home currently routes through MacBook-Pro-Aleksandr.local while NAS is offline; keep a Home routing peer online.

Matter uses 10.43.17.129:5580 through a separate narrow policy; Compose maps matter-server to this address. Moving HA from a home-node host network to a VPS does not automatically carry multicast discovery, Bluetooth or local device access. Moonraker 192.168.1.134:7125 refused connections after subnet routing was installed, requiring a service/listener or firewall check.

No physical-device command was issued as a test. Retain original Kubernetes manifests and private rollback backups. Never run two HA automation engines or two Zigbee2MQTT controllers against the same coordinator.
