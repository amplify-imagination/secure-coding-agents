#!/usr/bin/env bash
# DEMO ONLY — stands in for an AI coding agent. Shows which credential stores
# are reachable from $HOME. It only reads files; it exfiltrates nothing.
echo "agent> scanning \$HOME for reachable credential stores ..."
n=0
for p in \
  ".ssh/id_rsa|SSH private key" \
  ".aws/credentials|cloud credentials" \
  ".env|app secrets / API keys" \
  ".npmrc|registry token" \
  ".git-credentials|git login token" \
  ".config/Google/Chrome/Default/Cookies|browser session store"; do
  f="${p%%|*}"; d="${p#*|}"
  if [ -r "$HOME/$f" ]; then
    echo "agent> [FOUND] ~/$f   ($d)"; n=$((n+1))
  else
    echo "agent> [    ] ~/$f   (not present)"
  fi
done
if   [ "$n" -ge 4 ]; then echo "agent> $n credential stores reachable.   blast radius: WIDE OPEN"
elif [ "$n" -eq 0 ]; then echo "agent> $n credential stores reachable.   blast radius: CONTAINED"
else                      echo "agent> $n credential stores reachable."
fi
