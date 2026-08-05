# postgresql-pgroonga-pgvector

PostgreSQL Docker image with **[PGroonga](https://pgroonga.github.io/)** (full-text search) and **[pgvector](https://github.com/pgvector/pgvector)** (vector similarity) preinstalled.

Built from the official [`postgres`](https://hub.docker.com/_/postgres) image and Debian/PGDG extension packages.

## Images

| Registry | Image |
| --- | --- |
| GHCR | `ghcr.io/cubeplexai/postgresql-pgroonga-pgvector` |
| Docker Hub | `cubeplex/postgresql-pgroonga-pgvector` |

### Tags

| Tag | Meaning |
| --- | --- |
| `latest` | Latest build from `main` |
| `18.2` | Postgres patch version from [`versions.env`](./versions.env) |
| `18` | Postgres major |
| `18.2-pgroongaX.Y.Z-pgvectorA.B.C` | Full stack pin (discovered at build time from packages) |
| `sha-<short>` | Git commit |
| `v*` | Git tag (when present) |

Example:

```text
ghcr.io/cubeplexai/postgresql-pgroonga-pgvector:18.2-pgroonga4.0.6-pgvector0.8.2
```

## Quick start

```bash
docker run --rm -e POSTGRES_PASSWORD=postgres -p 5432:5432 \
  ghcr.io/cubeplexai/postgresql-pgroonga-pgvector:latest
```

Enable extensions in a database:

```sql
CREATE EXTENSION IF NOT EXISTS pgroonga;
CREATE EXTENSION IF NOT EXISTS vector;
```

Or with Compose:

```bash
docker compose up -d
```

## Build locally

```bash
# optional: edit versions.env first
set -a && source ./versions.env && set +a
docker build \
  --build-arg POSTGRES_IMAGE="${POSTGRES_IMAGE}" \
  --build-arg PG_MAJOR="${PG_MAJOR}" \
  -t postgresql-pgroonga-pgvector:local .
```

## CI / CD

[`.github/workflows/build-push.yml`](./.github/workflows/build-push.yml) builds multi-arch images (`linux/amd64`, `linux/arm64`) and pushes to **GHCR** and **Docker Hub**.

| Event | Behavior |
| --- | --- |
| PR (Dockerfile / versions / workflow) | Build amd64 only (no push) |
| Push to `main` | Multi-arch build + push |
| Tag `v*` | Multi-arch build + push |
| `workflow_dispatch` | Optional push; platforms configurable |

### Required secrets (org or repo)

| Secret | Purpose |
| --- | --- |
| `DOCKERHUB_TOKEN` | Docker Hub access token (read/write). Org-level secret is fine for public repos. |

GHCR uses the built-in `GITHUB_TOKEN` (`packages: write`).

### Optional variables / secrets

| Name | Default | Purpose |
| --- | --- | --- |
| `DOCKERHUB_USERNAME` (var or secret) | `cubeplex` | Docker Hub login username (not the GitHub org `cubeplexai`) |
| `DOCKERHUB_NAMESPACE` (var) | `cubeplex` | Docker Hub image namespace |

## Bumping the stack

1. Edit [`versions.env`](./versions.env) (`POSTGRES_IMAGE`, `PG_MAJOR`).
2. Merge to `main` (or run **Build and push image** manually).
3. CI installs current PGroonga/pgvector packages, discovers their versions, and publishes the composite tag.

## License

Same as PostgreSQL and the packaged extensions (see upstream licenses).
