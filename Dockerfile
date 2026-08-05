# Postgres + PGroonga + pgvector
# Base: official postgres image (Debian/PGDG packages for extensions)
ARG POSTGRES_IMAGE=postgres:18.2
FROM ${POSTGRES_IMAGE}

ARG PG_MAJOR=18
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg lsb-release; \
    . /etc/os-release; \
    curl -fsSL "https://packages.groonga.org/debian/groonga-apt-source-latest-${VERSION_CODENAME}.deb" \
        -o /tmp/groonga-apt-source.deb; \
    apt-get install -y --no-install-recommends /tmp/groonga-apt-source.deb; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        "postgresql-${PG_MAJOR}-pgdg-pgroonga" \
        "postgresql-${PG_MAJOR}-pgvector"; \
    apt-get purge -y --auto-remove curl gnupg lsb-release; \
    rm -rf /var/lib/apt/lists/* /tmp/groonga-apt-source.deb

LABEL org.opencontainers.image.title="postgresql-pgroonga-pgvector" \
      org.opencontainers.image.description="PostgreSQL with PGroonga and pgvector extensions" \
      org.opencontainers.image.source="https://github.com/cubeplexai/postgresql-pgroonga-pgvector" \
      org.opencontainers.image.licenses="PostgreSQL"
