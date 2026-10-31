# Dockhand registry

Docker Compose stacks deployed by Dockhand from this repository.

## Sure

The Sure stack lives in [`sure/compose.yaml`](sure/compose.yaml). The Dockhand Git stack uses the configured Infisical provider with secret path `/sure`.

The compose file reuses `PG_USER`, `PG_PASSWORD`, `SECRET_KEY_BASE`, and the three Active Record encryption keys from that path. It pins Sure to the live Kubernetes version (`0.7.4-alpha.7`) and PostgreSQL to `18.1`, matching the current cluster's database major and patch version.

The web service binds only to the VPS NetBird address, `100.71.86.199:3001`. The Sidekiq worker is behind the Compose `worker` profile and stays off until the final data cutover.

### Data migration gate

The existing Kubernetes instance remains the source of truth until a final consistent database dump and `/rails/storage` archive have been restored and checked in Dockhand. Only then should traffic be switched and the `worker` profile enabled. Migration and cutover are not complete yet.