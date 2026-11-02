# Home Assistant R2 configuration backups

Enabled in Dockhand stack homeassistant (ID 9) on 2026-11-02 after the user confirmed that Docker HA works. This supersedes the no-backup phase described in TRIAL.md.

The backup service mounts smarthome-homeassistant-data at /config read-only and runs backup.sh every 300 seconds. R2 destination and credentials are unchanged from the old Kubernetes backup sidecar, supplied through protected Dockhand variables. Kubernetes Deployment/homeassistant remains at zero replicas, so its backup sidecar is not an active writer.

Before the first Docker upload, the previous R2 backup.tgz was downloaded into a private timestamped backup directory on gw and validated. The initial pre-migration configuration archive and separate consistent recorder SQLite backup are also retained privately.

## Scope

The archive contains config/, including YAML, .storage and custom components. Like the original Kubernetes backup it excludes home-assistant_v2.db*, *.log*, config/backups and the Docker initialization marker. It does not back up recorder history. Archives contain credentials/tokens from HA configuration: do not commit or attach their contents.

## Verification and failure handling

Each cycle creates a private temporary archive, checks that tar can read it and that config/configuration.yaml exists, uploads to the original R2 backup.tgz key, then compares object ContentLength against the local archive size. A UTC success message records the verified size.

GNU tar exit 1 may occur when HA changes files during the live backup; the archive must still pass validation. Tar exit 2 or higher and validation failures prevent upload. An upload/HEAD failure exits the service; Docker's unless-stopped policy restarts it. The data mount is read-only. Temporary files are cleaned up on exit.

BACKUP_ONCE=1 executes the same cycle immediately for verification instead of starting the periodic loop. Docker host execution: docker exec -e BACKUP_ONCE=1 homeassistant-backup-1 /bin/sh /scripts/backup.sh. It does not require placing secret values in the command.

## Restoration and rollback

The existing init service restores backup.tgz only into a new uninitialized config volume, then applies exact NetBird trusted proxy settings offline. Existing initialized volumes are not overwritten by routine redeploys. Daily Git synchronization is enabled after verification of the new backup service; the HA image remains pinned to 2026.10.4.

Backups now contain Docker-era HTTP and other configuration changes. For rollback to the exact original Kubernetes configuration, use the privately retained pre-Docker archive rather than assuming the latest R2 object is still the old configuration. Never run Docker HA and Kubernetes HA concurrently.
