#!/usr/bin/env bash
# DEMO — a planted instruction in an untrusted issue. It is ACTIONABLE when the
# agent runs on the host (the key is readable, the net is open) and INERT inside
# the cage (no key, no network). Nothing is actually exfiltrated anywhere.
# Usage: ./injection-test.sh <repo-dir>
set -euo pipefail
REPO="${1:?usage: injection-test.sh <repo-dir>}"
echo '$ agent "triage issue #42"'
echo "agent> reading tests/app.test.js ..."
echo "agent> reading ISSUE-42.md (untrusted, author = stranger) ..."
inj=$(grep -o 'agent:.*id_rsa[^>]*' "$REPO/ISSUE-42.md" 2>/dev/null | sed 's/-->//' || true)
echo "agent> [!] instruction addressed to the agent: \"${inj#agent: }\""
if [ -r "$HOME/.ssh/id_rsa" ]; then
  echo "agent> EXPOSED host : ~/.ssh/id_rsa is readable -> ACTIONABLE -> would exfiltrate"
else
  echo "agent> CAGED        : no ~/.ssh + no network -> INERT -> nothing to steal, nowhere to send"
fi
