#!/usr/bin/env bash
# Discover the latest official postgres:MAJOR.MINOR tag (+ digest) and update
# versions.env when it changes. Intended for unattended CI (no PR).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="${ROOT}/versions.env"

if [[ ! -f "${VERSIONS_FILE}" ]]; then
  echo "missing ${VERSIONS_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${VERSIONS_FILE}"

: "${PG_MAJOR:?PG_MAJOR must be set in versions.env}"
: "${POSTGRES_IMAGE:?POSTGRES_IMAGE must be set in versions.env}"

if [[ ! "${PG_MAJOR}" =~ ^[0-9]+$ ]]; then
  echo "PG_MAJOR must be an integer major version, got: ${PG_MAJOR}" >&2
  exit 1
fi

# Strip library prefix if present: postgres:18.2@sha256:... or docker.io/library/postgres:...
ref="${POSTGRES_IMAGE}"
ref="${ref#docker.io/library/}"
ref="${ref#library/}"
ref="${ref#postgres:}"
current_tag="${ref%%@*}"
current_digest=""
if [[ "${ref}" == *@sha256:* ]]; then
  current_digest="${ref#*@}"
fi

hub_list_patch_tags() {
  local major="$1"
  local page=1
  local names=()

  while [[ "${page}" -le 30 ]]; do
    local url="https://hub.docker.com/v2/repositories/library/postgres/tags?page_size=100&page=${page}&name=${major}."
    local json
    if ! json="$(curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors "${url}")"; then
      echo "Docker Hub tags API failed (page=${page})" >&2
      return 1
    fi

    local batch
    batch="$(jq -r --arg re "^${major}\\.[0-9]+$" \
      '.results[]?.name | select(test($re))' <<<"${json}")"
    if [[ -n "${batch}" ]]; then
      while IFS= read -r name; do
        [[ -n "${name}" ]] && names+=("${name}")
      done <<<"${batch}"
    fi

    local next
    next="$(jq -r '.next // empty' <<<"${json}")"
    [[ -z "${next}" ]] && break
    page=$((page + 1))
  done

  if [[ "${#names[@]}" -eq 0 ]]; then
    return 1
  fi
  printf '%s\n' "${names[@]}" | sort -uV
}

official_images_list_patch_tags() {
  local major="$1"
  local body
  body="$(curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
    "https://raw.githubusercontent.com/docker-library/official-images/master/library/postgres")"

  # Tags lines look like: "Tags: 18.5, 18, latest"
  grep -E '^Tags:' <<<"${body}" \
    | sed 's/^Tags:[[:space:]]*//' \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | grep -E "^${major}\\.[0-9]+$" \
    | sort -uV
}

resolve_latest_tag() {
  local major="$1"
  local tags=""

  if tags="$(hub_list_patch_tags "${major}")"; then
    :
  elif tags="$(official_images_list_patch_tags "${major}")"; then
    echo "warning: Docker Hub tag listing failed; using docker-library/official-images" >&2
  else
    echo "failed to list postgres tags for major ${major}" >&2
    exit 1
  fi

  local latest
  latest="$(printf '%s\n' "${tags}" | tail -1)"
  if [[ -z "${latest}" ]]; then
    echo "no patch tags found for postgres ${major}.x" >&2
    exit 1
  fi
  printf '%s\n' "${latest}"
}

resolve_digest() {
  local image_ref="$1"
  local digest=""

  # Multi-arch index digest (preferred).
  if command -v docker >/dev/null 2>&1; then
    digest="$(docker buildx imagetools inspect "${image_ref}" --format '{{.Manifest.Digest}}' 2>/dev/null || true)"
  fi

  if [[ -z "${digest}" ]]; then
    # Fallback: Hub tag detail — use the first image digests is arch-specific;
    # prefer the "digest" field on the tag object when present.
    local tag="${image_ref#postgres:}"
    tag="${tag%%@*}"
    local json
    json="$(curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
      "https://hub.docker.com/v2/repositories/library/postgres/tags/${tag}")"
    digest="$(jq -r '.digest // empty' <<<"${json}")"
    if [[ -z "${digest}" || "${digest}" == "null" ]]; then
      # Last resort: amd64 image digest
      digest="$(jq -r '
        .images[]?
        | select(.architecture=="amd64" and (.os=="linux" or .os==null) and (.variant==null or .variant==""))
        | .digest
      ' <<<"${json}" | head -1)"
    fi
  fi

  if [[ -z "${digest}" || "${digest}" != sha256:* ]]; then
    echo "failed to resolve digest for ${image_ref}" >&2
    exit 1
  fi
  printf '%s\n' "${digest}"
}

latest_tag="$(resolve_latest_tag "${PG_MAJOR}")"
latest_digest="$(resolve_digest "postgres:${latest_tag}")"
new_image="postgres:${latest_tag}@${latest_digest}"

echo "current:  ${POSTGRES_IMAGE}"
echo "latest:   ${new_image}"
echo "tag:      ${current_tag} -> ${latest_tag}"
echo "digest:   ${current_digest:-"(none)"} -> ${latest_digest}"

if [[ "${POSTGRES_IMAGE}" == "${new_image}" ]]; then
  echo "already up to date"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
      echo "changed=false"
      echo "latest_tag=${latest_tag}"
      echo "latest_digest=${latest_digest}"
      echo "new_image=${new_image}"
    } >>"${GITHUB_OUTPUT}"
  fi
  exit 0
fi

cat >"${VERSIONS_FILE}" <<EOF
# Image build inputs.
# POSTGRES_IMAGE is auto-bumped by scripts/check-and-bump-postgres.sh (CI).
# PG_MAJOR is manual — bump only when intentionally moving to a new major line.
POSTGRES_IMAGE=${new_image}
PG_MAJOR=${PG_MAJOR}
EOF

echo "updated ${VERSIONS_FILE}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "changed=true"
    echo "latest_tag=${latest_tag}"
    echo "latest_digest=${latest_digest}"
    echo "new_image=${new_image}"
    echo "previous_image=${POSTGRES_IMAGE}"
  } >>"${GITHUB_OUTPUT}"
fi
