# EP01c — Cage GitHub Copilot CLI (BYOK + Podman)

The same caging discipline as EP01/EP01a, applied to the agent most people have at work:
**GitHub Copilot's command-line agent**. Five walls, all free, on the tool you already pay for —
then folded into one launch command.

GitHub now ships its own `/sandbox` (one wall: shell isolation, off by default). This goes further:
where it runs, which brain it uses, which tools it can reach, which skills it loads, and what it spends.

## The walls

| Wall | Concern | This repo |
|---|---|---|
| 1 · Where it runs | runs as you, reaches everything | `cage` + `Dockerfile` — read-only repo, throwaway copy, empty home, caps dropped |
| 2 · Which brain | prompts + code leave to a vendor | BYOK → local model (LM Studio), `COPILOT_OFFLINE=true` |
| 3 · Which tools | every connector is a new door | `copilot mcp add` + enterprise registry policy (server-side) |
| 3b · What it does | a skill can call a tool | `hooks/cage-hook.sh` — preToolUse camera, logs + can deny |
| 4 · Which skills | public marketplaces ship malware | private plugin marketplace — install only what you vetted |
| 5 · What it spends | a loop burns money unwatched | `litellm_config.yaml` — DB-backed budget gateway that refuses |

## Quickstart — cage a repo and ship an edit

Full step-by-step (verified, copy-paste): **[CAGE-A-REPO.md](CAGE-A-REPO.md)**

```bash
podman build -t copilot-cage .                       # the cage image (Node + Copilot CLI, no git/keys)
# load a 12B+ model in LM Studio (a 4B will mangle edits), then:
./cage ./example-repo "Replace the unsafe os.system call in runner.py with subprocess.run(shlex.split(cmd), check=True)."
# review the printed diff, then apply + push from OUTSIDE the cage, where your keys live:
#   git -C ./example-repo apply <patch> && git commit -am "..." && git push
```

The agent works on a **copy**, hands you a **diff**, and **can't push** — because the box has no keys.
You review and push. The agent proposes; you commit.

## Files

| File | What it is |
|---|---|
| `Dockerfile` | the minimal cage image — Node + Copilot CLI, deliberately no git/ssh/creds |
| `cage` | the launcher: five walls behind one command |
| `hooks/cage-hook.sh`, `hooks/cage.json` | the preToolUse camera (logs every tool call, can deny) |
| `litellm_config.yaml` | the budget gateway that refuses past a hard cap |
| `example-repo/runner.py` | a deliberately unsafe file to fix in the demo |
| `CAGE-A-REPO.md` | the full, verified walkthrough |

> Network egress lock (allow only the model/gateway + approved hosts) is the next wall — host firewall step, WIP.
