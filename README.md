# Dockhand registry

Docker Compose stacks deployed by Dockhand from this repository. Git is the desired-state source; stack secrets are supplied by the Infisical provider.

## Stacks

- [`garage/compose.yaml`](garage/compose.yaml): single-node Garage S3 service. Infisical path: `/garage`. S3 endpoint on the shared Docker network: `http://garage:3900`; published only on NetBird at `100.71.86.199:3900` for the NetBird reverse proxy.
- [`postgres/compose.yaml`](postgres/compose.yaml): shared PostgreSQL 18.1. Infisical path: `/sure` for the existing PostgreSQL bootstrap credentials. The database is published only on NetBird at `100.71.86.199:5432`; Docker stacks use `postgres:5432` on `shared-services`.
- [`pgadmin/compose.yaml`](pgadmin/compose.yaml): shared pgAdmin 4. Infisical path: `/pgadmin`; preloads the shared PostgreSQL server and is published only on NetBird at `100.71.86.199:3003`.
- [`karakeep/compose.yaml`](karakeep/compose.yaml): Karakeep 0.32.0, Meilisearch, and Chrome. Infisical path: `/karakeep`; persistent data volumes are `karakeep-data` and `karakeep-meilisearch-data`. App endpoint: `http://100.71.86.199:3002`.
- [`sure/compose.yaml`](sure/compose.yaml): Sure 0.7.4-alpha.7 and Redis. Infisical path: `/sure`; Sure connects to the shared `postgres` service. The previous `sure_postgres-data` volume and rollback-only Postgres service are retained.

All application stacks that use shared services join the external Docker network `shared-services`, created by the PostgreSQL stack.

## Database notes

Sure currently uses the same PostgreSQL bootstrap account it used in its former dedicated database container. Create distinct least-privilege roles and databases for future applications instead of sharing the Sure account. Karakeep's supported data store remains SQLite in `/data`; its S3 objects are stored in Garage.

pgAdmin uses the `postgres` Docker DNS name on `shared-services`. The PostgreSQL port is also published only on NetBird for external tools.

## Migration and rollback

Keep the existing Kubernetes PVCs and Sure's old Docker volume until both cutovers are verified. Back up Karakeep's SQLite data and S3 assets before switching traffic. The Karakeep and Sure stacks must not be synced until their destination data and Infisical settings are ready.
