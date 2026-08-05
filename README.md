# postgresql-pgroonga-pgvector

PostgreSQL Docker image with **[PGroonga](https://pgroonga.github.io/)** (full-text search) and **[pgvector](https://github.com/pgvector/pgvector)** (vector similarity) preinstalled.

Built from the official [`postgres`](https://hub.docker.com/_/postgres) image and Debian/PGDG extension packages.

## Images

| Registry | Image |
| --- | --- |
| GHCR | `ghcr.io/cubeplexai/postgresql-pgroonga-pgvector` |
| Docker Hub | [`cubeplex/postgresql-pgroonga-pgvector`](https://hub.docker.com/r/cubeplex/postgresql-pgroonga-pgvector) |

Docker Hub full description is maintained in [`docker-hub-readme.md`](./docker-hub-readme.md) and synced by CI.

### Tags

| Tag | Meaning |
| --- | --- |
| `latest` | Latest build from `main` |
| `18.4` | Postgres patch version (digest pin in `versions.env` is **not** part of the tag) |
| `18` | Postgres major |
| `18.4-pgroongaX.Y.Z-pgvectorA.B.C` | Full stack pin (extension package versions at build time) |
| `sha-<short>` | Git commit |
| `v*` | Git tag (when present) |

Example:

```text
cubeplex/postgresql-pgroonga-pgvector:18.4
cubeplex/postgresql-pgroonga-pgvector:18.4-pgroonga4.0.8-pgvector0.8.6
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

### Auto-bump official Postgres base

[`.github/workflows/check-upstream.yml`](./.github/workflows/check-upstream.yml) runs **daily** (and on demand):

1. Looks up the latest official `postgres:<PG_MAJOR>.N` tag (Docker Hub, with fallback to [docker-library/official-images](https://github.com/docker-library/official-images)).
2. Resolves the multi-arch **digest**.
3. If tag or digest differs from [`versions.env`](./versions.env), commits  
   `POSTGRES_IMAGE=postgres:X.Y@sha256:…` **directly to `main`** (no PR).
4. Explicitly dispatches `build-push.yml` (GitHub does **not** start other
   workflows from a `GITHUB_TOKEN` push — recursion guard).

`PG_MAJOR` is **not** auto-advanced (major upgrades stay manual).

```bash
# Manual run
gh workflow run check-upstream.yml -R cubeplexai/postgresql-pgroonga-pgvector
```

### Required secrets (org or repo)

| Secret | Purpose |
| --- | --- |
| `DOCKERHUB_TOKEN` | Docker Hub [access token](https://docs.docker.com/docker-hub/access-tokens/). Org-level secret is fine for public repos. |

Token scopes:

| Scope | Image push | Hub README / short description |
| --- | --- | --- |
| Read & Write | yes | no (API returns **403 Forbidden**) |
| **Read, Write, Delete** | yes | **yes** |

If description sync fails with `Forbidden`, recreate the PAT with **Read, Write, Delete**, update org secret `DOCKERHUB_TOKEN`, then re-run **Update Docker Hub README**.

GHCR uses the built-in `GITHUB_TOKEN` (`packages: write`).

### Optional variables / secrets

| Name | Default | Purpose |
| --- | --- | --- |
| `DOCKERHUB_USERNAME` (var or secret) | `cubeplex` | Docker Hub login username (not the GitHub org `cubeplexai`) |
| `DOCKERHUB_NAMESPACE` (var) | `cubeplex` | Docker Hub image namespace |

### Docker Hub README source

[`docker-hub-readme.md`](./docker-hub-readme.md) is synced to [hub.docker.com/r/cubeplex/postgresql-pgroonga-pgvector](https://hub.docker.com/r/cubeplex/postgresql-pgroonga-pgvector) by [`.github/workflows/dockerhub-readme.yml`](./.github/workflows/dockerhub-readme.yml).

## Bumping the stack

**Patch releases (automatic):** leave it to **Check upstream Postgres** — or run that workflow manually.

**Major line (manual):**

1. Edit [`versions.env`](./versions.env): set `PG_MAJOR` and `POSTGRES_IMAGE` (e.g. `postgres:19.0`).
2. Push to `main` (or run **Build and push image**).
3. CI installs current PGroonga/pgvector packages, discovers versions, and publishes the composite tag.

## License

Same as PostgreSQL and the packaged extensions (see upstream licenses).
