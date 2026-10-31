# Dockhand registry

Docker Compose stacks deployed by Dockhand from this repository.

## Sure

The Sure stack lives in [`sure/compose.yaml`](sure/compose.yaml). Dockhand should bind the configured Infisical provider to the stack and use secret path `/sure`.

The compose file reuses the existing `PG_USER`, `PG_PASSWORD`, `SECRET_KEY_BASE`, and Active Record encryption keys from that Infisical path. It pins the application to the version already declared by the Kubernetes Helm release (`0.7.4-alpha.7`) and keeps PostgreSQL on major version 16.

The stack binds its web port only to the VPS NetBird address, `100.71.86.199:3001`.

### Data migration gate

Do not deploy the Sure stack until the existing PostgreSQL database and `/rails/storage` files have been backed up and imported. The existing Kubernetes instance remains the source of truth until the restored instance has been checked and traffic has been switched. The current VPS has no route to the Kubernetes API or Sure database, so this migration has not been performed.