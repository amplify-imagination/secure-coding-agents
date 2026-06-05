# EP01c — Cage GitHub Copilot CLI (BYOK + Podman)

The same caging discipline as EP01/EP01a, applied to the agent most people have at work:
**GitHub Copilot's command-line agent**. Real walls, all free, on the tool you already pay for —
then folded into one launch command.

GitHub now ships its own `/sandbox` (one wall: shell isolation, off by default). This goes further:
where it runs, which brain it uses, what it can reach on the network, and what it spends.

## The walls

| Wall | Concern | This repo |
|---|---|---|
| 1 · Where it runs | runs as you, reaches everything | `cage` + `Dockerfile` — read-only repo, throwaway copy, empty home, caps dropped |
| 2 · Which brain | prompts + code leave to a vendor | BYOK → local model (LM Studio), `COPILOT_OFFLINE=true` |
| 3 · Network | a prompt-injected agent phones out | `cage-noegress` sealed network + `relay.js` — reaches **only** your model |
| 3b · What it does | a skill can call a tool | `hooks/cage-hook.sh` — preToolUse camera, logs + can deny (optional) |
| 4 · What it spends | a loop burns money unwatched | `litellm_config.yaml` — budget gateway that refuses (optional) |

## Quickstart — cage a repo and ship an edit

Full step-by-step (verified, copy-paste): **[CAGE-A-REPO.md](CAGE-A-REPO.md)**

```bash
podman build -t copilot-cage .          # the cage image (Node + Copilot CLI, no git/keys)
# start a coder model in LM Studio on :1234 (Qwen2.5-Coder-7B works well; a 4B will mangle edits)

./cage example-repo                       # builds the sealed network + relay, drops you in the caged agent
# then just tell it, specifically:
#   "run_job in runner.py uses os.system — propose a minimal, safe diff."
# it proposes a diff and writes nothing (Changes +0 -0 is correct).
# review it, then apply + push from OUTSIDE the cage, where your keys live:
#   cd example-repo && git apply <diff> && git commit -am "..." && git push
```

The agent works on a **copy**, can reach **only your model** (not the internet, not GitHub),
hands you a **diff**, and **can't push** — because the box has no keys. You review and ship.

Prove the network wall yourself:

```bash
podman run --rm --network cage-noegress -v ./probe.js:/probe.js:ro \
  --entrypoint node copilot-cage /probe.js
#  the model (via relay)  reachable  ·  the open internet  blocked  ·  github.com  blocked
```

## Files

| File | What it is |
|---|---|
| `Dockerfile` | the minimal cage image — Node + Copilot CLI, deliberately no git/ssh/creds |
| `cage` | the launcher: every wall behind one command (incl. the sealed network + relay) |
| `relay.js` | the network allowlist — forwards only to your local model |
| `probe.js` | proves the wall: model reachable, internet + GitHub blocked |
| `example-repo/runner.py` | a deliberately unsafe file to fix in the demo |
| `hooks/cage-hook.sh`, `hooks/cage.json` | optional preToolUse camera (logs every tool call, can deny) |
| `litellm_config.yaml` | optional budget gateway that refuses past a hard cap |
| `CAGE-A-REPO.md` | the full, verified walkthrough |

> **Never mount the Docker/Podman socket into the cage.** A socket mount equals host root — it hands the agent the exact escape this cage exists to prevent.
