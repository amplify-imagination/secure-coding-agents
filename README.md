# Secure Coding Agents — reproducible builds

Cage an AI coding agent so that a prompt-injected or misfiring agent **can't read your secrets and can't phone home** — free, rootless, copy-paste. Companion code for the *Secure Coding Agents* video series.

> ⚠️ **Run everything here on a throwaway machine with FAKE keys.** Never on your real laptop, never with real credentials. This is a generic, educational setup — **not** a description of any company's internal tooling.

## The idea: capability over tooling

You can't make a language-model agent reliably *obey* a rule — especially when an attacker can write rules too (a poisoned README, a planted issue). So don't rely on obedience; remove the ability. **Name what must be true, then pick a tool:**

1. **Empty home** — the agent's `$HOME` has none of your dotfiles or keys
2. **Repo read-only** — it reads the code, it can't tamper with it
3. **No credentials in its environment** — nothing for an injected instruction to find
4. **Network off, or a tight allowlist** — nowhere to exfiltrate to

The tool is interchangeable. This repo demos **bubblewrap** (free, rootless, no daemon, one `apt install`) because it runs anywhere with zero setup. It's a clean way to *show the capabilities* — not a claim that it's the best tool. For real use, pick by risk: see [`FREE_TIER_TOOLS.md`](FREE_TIER_TOOLS.md).

## Quickstart

```bash
git clone <this-repo> && cd secure-coding-agents
sudo apt install -y bubblewrap        # one-time, Linux
./scripts/setup-lab.sh                # makes ./lab with FAKE keys + a sample repo
export REPO="$PWD/lab/repo" VICTIM_HOME="$PWD/lab/victim_home"

# 1) Measure the blast radius (agent runs straight on the host)
HOME="$VICTIM_HOME" bash "$REPO/agent_scan.sh"             # -> 6 stores, WIDE OPEN

# 2) Same scan, same fake keys, inside the cage
./scripts/cage-bwrap.sh "$REPO" bash /work/agent_scan.sh   # -> 0 reachable, CONTAINED

# 3) Prove it against a prompt-injection attack
HOME="$VICTIM_HOME" ./scripts/injection-test.sh "$REPO"               # ACTIONABLE on host
./scripts/cage-bwrap.sh "$REPO" bash /work/injection-test.sh /work   # INERT in the cage
```

No Docker required. Already on Docker/Podman? `./scripts/cage-docker.sh "$REPO"` does the same cage.

## Scripts

| Script | What it does |
|---|---|
| `scripts/setup-lab.sh` | Create a fake "victim" home (dummy SSH key, cloud creds, tokens, cookies) + a sample repo. Throwaway only. |
| `scripts/agent_scan.sh` | Illustrative agent: which credential stores are reachable from `$HOME`. |
| `scripts/cage-bwrap.sh` | Run any command inside the bubblewrap cage (empty home, repo read-only, no network). |
| `scripts/cage-docker.sh` | The same cage with Docker / Podman. |
| `scripts/injection-test.sh` | A planted instruction in an untrusted issue: *actionable* on the host, *inert* in the cage. |

## Choosing a tool by risk

Capability-first and tiered (low-risk → rootless container or dev container; critical → microVM). See [`FREE_TIER_TOOLS.md`](FREE_TIER_TOOLS.md).

## Videos

- **EP01 — The Blast Radius of an AI Coding Agent** (high-level): _link_
- **EP01a — Cage Your AI Coding Agent** (walkthrough): _link_

## License

Suggested: MIT — add a `LICENSE` file with your name.
