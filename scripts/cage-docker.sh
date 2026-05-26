#!/usr/bin/env bash
# Docker / Podman variant of the cage (same four capabilities):
#   empty home, repo read-only, no creds in env, no network.
# Usage: ./cage-docker.sh <repo-dir> [image] [command...]
#   e.g. ./cage-docker.sh "$REPO"                       # runs agent_scan.sh
#        ./cage-docker.sh "$REPO" debian:stable-slim bash /work/agent_scan.sh
set -euo pipefail
REPO="${1:?usage: cage-docker.sh <repo-dir> [image] [command...]}"; shift || true
IMG="${1:-debian:stable-slim}"; [ $# -gt 0 ] && shift || true
RUNTIME="$(command -v podman || command -v docker)"
[ -n "$RUNTIME" ] || { echo "need docker or podman" >&2; exit 1; }

exec "$RUNTIME" run --rm -i \
  --tmpfs /home/agent -e HOME=/home/agent \
  -v "$REPO":/work:ro -w /work \
  --network none \
  "$IMG" "${@:-bash /work/agent_scan.sh}"
