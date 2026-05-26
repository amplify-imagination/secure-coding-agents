#!/usr/bin/env bash
# Run a command inside a bubblewrap cage:
#   - empty tmpfs home (no dotfiles, no keys)
#   - the repo mounted READ-ONLY at /work
#   - minimal read-only OS
#   - --unshare-all => no network
# Usage: ./cage-bwrap.sh <repo-dir> <command...>
#   e.g. ./cage-bwrap.sh "$REPO" bash /work/agent_scan.sh
set -euo pipefail
REPO="${1:?usage: cage-bwrap.sh <repo-dir> <command...>}"; shift
command -v bwrap >/dev/null || { echo "bubblewrap not installed: sudo apt install -y bubblewrap" >&2; exit 1; }

exec bwrap \
  --unshare-all \
  --tmpfs /home/agent --setenv HOME /home/agent \
  --ro-bind /usr /usr --ro-bind /bin /bin --ro-bind /lib /lib \
  $([ -d /lib64 ] && printf -- '--ro-bind /lib64 /lib64') \
  --ro-bind /etc /etc --proc /proc --dev /dev \
  --ro-bind "$REPO" /work --chdir /work \
  "$@"
