# Home Assistant trial on gw (2026-11-02)

Dockhand stack homeassistant (ID 9) runs the latest stable release verified from the official home-assistant/core release API: 2026.10.4. The previous Kubernetes instance was already running 2026.10.4 with the identical image digest 23f4dfbb69ce76315dbc4de7915504f1c2dcecd7ca2648113a493a385972e133. This is an environment/configuration migration trial, not a version-to-version upgrade.

Compose includes only the R2 init service and Home Assistant. There is deliberately no backup service and automatic Git synchronization is disabled for the trial. R2 credentials are protected Dockhand environment variables; the Infisical client remains blocked by Cloudflare. No secret values are committed.

The init restores the config/ subtree from the existing R2 backup.tgz into smarthome-homeassistant-data. R2 config archives exclude recorder SQLite as in the original backup. A separate consistent recorder SQLite backup and validated R2 configuration archive were saved privately on gw before shutdown, for rollback. The Docker trial does not write configuration changes back to R2.

Kubernetes Deployment/homeassistant in smarthome is temporarily at replicas=0. The committed smarthome/legacy-homeassistant-patch.yaml records the shutdown. The original Deployment is retained. Kubernetes Matter and the MQTT compatibility broker remain running.

## Environment changes identified

- Matter used the Kubernetes DNS name matter-server. Compose maps it to the existing service 10.43.17.129; NetBird permits gw to this specific resource on TCP 5580. Connectivity was verified from the HA container.
- Restored HTTP settings trusted only the original private network ranges. HA rejected forwarded requests from the NetBird address of gw. The current release has already migrated HTTP settings to .storage/http: yaml_migration_done=true means changing configuration.yaml alone does not change the running HTTP server. The init now adds only the current NetBird proxy peers 100.71.109.63/32 and 100.71.222.49/32 plus gw 100.71.86.199/32 to the saved stable/pending HTTP configuration, offline before HA starts, and mirrors those addresses in the old YAML list. Review these exact proxy addresses if NetBird replaces peers.
- The old YAML http section is still present for comparison and may produce a migration repair notice; migrated HTTP storage is authoritative.
- Home Assistant MQTT still uses 192.168.1.163:1883. The existing broker and Docker Mosquitto bridge preserve that endpoint.
- Moonraker points to 192.168.1.134:7125; connection errors on the VPS indicate missing access to that LAN endpoint, not a YAML validation error. Other LAN discovery, multicast, Bluetooth, Sonos, HomeKit/Thread or local integrations may need network changes when moving from home-node hostNetwork to a VPS bridge network.

The source and restored configuration passed the built-in check_config command. This does not validate every integration or physical automation. No physical-device command was issued as a test.

## Rollback

Stop Docker Home Assistant before starting Kubernetes Home Assistant again. The old R2 archive remains unchanged by this trial. Use the privately validated config-from-r2.tgz and recorder.db if a full original-state restoration is required. Do not restore a recorder database upgraded by a newer future version into an older release.
