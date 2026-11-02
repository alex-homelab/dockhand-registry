# Smarthome stacks — staged, not deployed

Based on the running Kubernetes smarthome namespace captured 2026-11-02. Images pinned to running digests. Dockhand stacks mosquitto, zigbee2mqtt and homeassistant use their respective compose.yaml paths, shared-services network, Infisical provider and /mosquitto, /zigbee2mqtt, /homeassistant secret paths. deployNow=false, autoUpdate=false until cutover.

## Secret provisioning required

- /mosquitto: CONFIG_B64 from ConfigMap mosquitto-config/mosquitto.conf; MOSQUITTO_PASSWORD_B64 from mosquitto-password/password.txt. Both base64 encoded. Never commit the password hashes.
- /zigbee2mqtt: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ENDPOINT, AWS_REGION, BUCKET from Secret r2-credentials. CONFIG_B64 from zigbee2mqtt-config/configuration.yaml. MQTT_USER and MQTT_PASSWORD from mqtt-credentials/user,password. Compose overrides the MQTT server to mqtt://mosquitto:1883.
- /homeassistant: the five R2 variables from Secret r2-credentials-ha.

Infisical API provisioning is currently blocked by HTTP 403. These paths have not been populated by this change. No secret values are in this repository.

## Restore and backup

One-shot init must complete successfully before each app starts. Persistent named volumes replace emptyDir. An initialization marker avoids restoring over existing initialized data. Failed restores block startup.

Home Assistant restores the config/ subtree from backup.tgz. Its backup sidecar uploads backup.tgz every 300 seconds, excluding recorder SQLite, logs and nested backups, matching Kubernetes. This is a config-only backup, not recorder history. tar/gzip are installed at runtime as in the source deployment.

Zigbee2MQTT restores database.db, state.json, coordinator_backup.json and configuration.yaml; ConfigMap fallback is used only if downloading configuration.yaml fails. This fixes the original shell operator-precedence bug that could overwrite a successful download. Backup uploads the four original object keys every 600 seconds. Credentials are provided as application env overrides.

Mosquitto initializes config and password file with UID/GID 1883. Its source config disables MQTT persistence; that is preserved. Kubernetes had no Mosquitto R2 backup container, so none is added here.

Backups mount data read-only. Upload failures exit and restart the sidecar. They use the ORIGINAL R2 bucket/key locations: never run old and new backup writers concurrently.

## Activation gates

1. Fix Infisical API access, provision secrets and verify required R2 objects privately.
2. Provide VPS connectivity to the existing Zigbee TCP coordinator at 192.168.1.1:20108, currently unreachable. Never run two Zigbee2MQTT instances against one coordinator.
3. Choose Home Assistant placement: Kubernetes used home-node hostNetwork. VPS Compose binds only NetBird through bridge networking; LAN multicast discovery, Bluetooth, local device access and Matter connectivity do not transfer automatically. Use a home Docker environment and adapt networking if discovery is required.
4. At cutover, stop old apps and backup writers, capture final backups, deploy Mosquitto before Zigbee2MQTT and Home Assistant. Update restored HA MQTT/Matter endpoints via supported settings. Verify devices/automations before switching reverse proxies.
5. Enable scheduled Git sync only after verified deployment. Retain Kubernetes data and backups for rollback.
