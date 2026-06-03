#!/usr/bin/env bash
# preToolUse hook — the camera. Reads the tool call on stdin, logs it, can deny.
payload="$(cat)"
printf '%s %s\n' "$(date -u +%FT%TZ)" "$payload" >> "${CAGE_LOG:-/tmp/cage-tools.log}"
if printf '%s' "$payload" | grep -Eiq 'id_rsa|\.ssh|/etc/shadow|rm[[:space:]]+-rf[[:space:]]+/|(paste|webhook|ngrok)\.'; then
  printf '{"permissionDecision":"deny","reason":"blocked by cage hook"}\n'; exit 0
fi
printf '{"permissionDecision":"allow"}\n'
