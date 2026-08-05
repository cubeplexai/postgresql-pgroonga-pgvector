# postgresql-pgroonga-pgvector

PostgreSQL with **[PGroonga](https://pgroonga.github.io/)** (full-text search) and **[pgvector](https://github.com/pgvector/pgvector)** (vector similarity) preinstalled.

Built from the official [`postgres`](https://hub.docker.com/_/postgres) image using Debian/PGDG extension packages. Multi-arch: `linux/amd64`, `linux/arm64`.

**Source:** [github.com/cubeplexai/postgresql-pgroonga-pgvector](https://github.com/cubeplexai/postgresql-pgroonga-pgvector)

Also published on GHCR: `ghcr.io/cubeplexai/postgresql-pgroonga-pgvector`

---

## Quick start

```bash
docker run --rm -e POSTGRES_PASSWORD=postgres -p 5432:5432 \
  cubeplex/postgresql-pgroonga-pgvector:latest
```

Enable the extensions:

```sql
CREATE EXTENSION IF NOT EXISTS pgroonga;
CREATE EXTENSION IF NOT EXISTS vector;
```

### Docker Compose

```yaml
services:
  postgresql:
    image: cubeplex/postgresql-pgroonga-pgvector:latest
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    volumes:
      - pgdata:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

---

## Tags

| Tag | Meaning |
| --- | --- |
| `latest` | Latest build from `main` |
| `18` | Postgres major |
| `18.4` | Postgres patch version |
| `18.4-pgroongaX.Y.Z-pgvectorA.B.C` | Full stack pin (package versions at build time) |
| `sha-<short>` | Git commit |
| `v*` | Git release tag (when present) |

**Recommended for production:** pin the full composite tag, for example:

```text
cubeplex/postgresql-pgroonga-pgvector:18.4-pgroonga4.0.8-pgvector0.8.6
```

---

## What's included

| Component | Source |
| --- | --- |
| PostgreSQL | Official `postgres` image |
| PGroonga | `postgresql-*-pgdg-pgroonga` (Groonga apt) |
| pgvector | `postgresql-*-pgvector` (PGDG) |

Configuration and data layout match the official Postgres image (`POSTGRES_*` env vars, `/var/lib/postgresql`, entrypoint scripts).

---

## Environment variables

Same as the [official Postgres image](https://hub.docker.com/_/postgres):

| Variable | Description |
| --- | --- |
| `POSTGRES_PASSWORD` | Superuser password (**required** unless trust auth) |
| `POSTGRES_USER` | Superuser name (default `postgres`) |
| `POSTGRES_DB` | Default database (default: same as user) |
| `POSTGRES_INITDB_ARGS` | Extra `initdb` arguments |
| `PGDATA` | Data directory |

---

## Example: PGroonga + pgvector

```sql
CREATE EXTENSION IF NOT EXISTS pgroonga;
CREATE EXTENSION IF NOT EXISTS vector;

-- Full-text search
CREATE TABLE docs (
  id bigserial PRIMARY KEY,
  body text
);
CREATE INDEX docs_body_pgroonga ON docs USING pgroonga (body);

-- Vectors
CREATE TABLE items (
  id bigserial PRIMARY KEY,
  embedding vector(3)
);
CREATE INDEX items_embedding_ivfflat ON items
  USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
```

---

## Build & CI

Images are built automatically from the GitHub repository on every push to `main` (and on tags), then pushed here and to GHCR.

To bump the Postgres base version, edit `versions.env` in the source repo and merge to `main`.

---

## License

PostgreSQL and the packaged extensions retain their upstream licenses. See the [source repository](https://github.com/cubeplexai/postgresql-pgroonga-pgvector) for details.
