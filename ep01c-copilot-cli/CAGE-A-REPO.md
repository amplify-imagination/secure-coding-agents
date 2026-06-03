# Cage GitHub Copilot CLI against a real repo — full walkthrough

Let an AI coding agent work on a real Git repo while it **cannot touch your real files, your keys, your network, or push anything**. The agent works on a throwaway copy and proposes a diff. *You* review it, apply it, and push — from outside the cage, where your credentials live.

This is the loop shown in the video, every command verified on macOS (Apple Silicon) with Podman.

```
clone ──► throwaway copy ──► caged agent edits the copy ──► diff ──► (agent can't push) ──► you apply + commit + push ──► GitHub
                 ▲                                                          ▲
        your real repo stays read-only & untouched              your keys never enter the box
```

---

## What you need (one-time)

- **Podman** (rootless) — `brew install podman && podman machine init && podman machine start`
- **A local model server** — [LM Studio](https://lmstudio.ai). Load a model that can actually edit code. A ~12B model (e.g. `gemma-4-12b`, or a coder like `Qwen2.5-Coder-7B`) makes clean edits; a ~4B model will mangle them. Give it a 32k context window (the agent's own prompt is large).
- **GitHub Copilot CLI** — `npm install -g @github/copilot`. We run it in **BYOK** (bring-your-own-key) mode, so it needs **no GitHub login**.
- **The cage image** — built below.

---

## 0. Build the cage image (once)

The image is deliberately minimal: **Node + the Copilot CLI, and nothing else** — no `git`, no SSH, no credentials. That's what makes "the agent can't push" true by construction, not by a rule.

`Dockerfile`:

```dockerfile
# Deliberately NO git, NO ssh, NO credentials — the agent can edit, but never push.
FROM node:22-slim
RUN npm install -g @github/copilot@1.0.57
WORKDIR /work
```

```bash
podman build -t copilot-cage .
```

---

## 1. Get the repo (a normal developer clone)

```bash
git clone https://github.com/you/your-repo.git ~/work/your-repo
```

This is your real repo, with its `.git` and history. It will stay **read-only and untouched** throughout.

## 2. Make a throwaway working copy

The agent edits a *copy*, never your real clone:

```bash
cp -r ~/work/your-repo ~/work/agent-work
```

## 3. Start the local model

In LM Studio: load your model and start its server (bind to all interfaces so the container can reach it):

```bash
lms load <your-model> --context-length 32768 --gpu max
lms server start --bind 0.0.0.0
# confirm the exact model id the server advertises:
curl -s http://localhost:1234/v1/models
```

Note the `id` you get back (e.g. `google/gemma-4-12b`) — you'll pass it as `COPILOT_MODEL`.

## 4. Run the caged agent

```bash
podman run --rm \
  --userns=keep-id \
  --tmpfs /home/agent --env HOME=/home/agent \
  -v ~/work/your-repo:/src:ro \
  -v ~/work/agent-work:/work \
  -w /work \
  --cap-drop=ALL \
  --env COPILOT_PROVIDER_BASE_URL=http://host.containers.internal:1234/v1 \
  --env COPILOT_PROVIDER_API_KEY=lm-studio \
  --env COPILOT_MODEL=google/gemma-4-12b \
  --env COPILOT_OFFLINE=true \
  --entrypoint sh copilot-cage -c '
    copilot -p "In runner.py, replace the unsafe os.system(cmd) in run_job with subprocess.run(shlex.split(cmd), check=True), and fix the imports. Use your edit tool to write and save the change." --allow-all
  '
```

What each line does — these are the cage walls:

| Flag | What it does |
|---|---|
| `--userns=keep-id` | container "root" maps to your unprivileged user, not real root |
| `--tmpfs /home/agent` + `HOME=/home/agent` | an **empty, throwaway home** — no dotfiles, no keys to find |
| `-v …/your-repo:/src:ro` | your real repo, mounted **read-only** for reference |
| `-v …/agent-work:/work` | the **writable copy** — all edits land here, never in your real repo |
| `--cap-drop=ALL` | drop every Linux capability |
| `COPILOT_PROVIDER_BASE_URL=…host.containers.internal:1234` | point the agent at **your local model** (the host, seen from inside the container) |
| `COPILOT_OFFLINE=true` | no telemetry, no phoning home, no GitHub login |
| `--allow-all` | let the agent use its tools without interactive prompts (safe — it's caged) |

> **Tip:** read the model id straight from the server so you never hardcode the wrong one:
> `--env COPILOT_MODEL=$(curl -s http://localhost:1234/v1/models | python3 -c "import sys,json;print(json.load(sys.stdin)['data'][0]['id'])")`

## 5. Get the diff (your real repo is still untouched)

The agent edited the *copy*. Pull out exactly what it proposes:

```bash
git -C ~/work/agent-work --no-pager diff            # review it
git -C ~/work/agent-work diff > /tmp/agent.patch    # save the patch
```

Confirm your real repo never changed:

```bash
git -C ~/work/your-repo status        # clean
```

## 6. Prove the agent can't push (no keys in the box)

```bash
podman run --rm --userns=keep-id --tmpfs /home/agent --env HOME=/home/agent \
  --cap-drop=ALL --entrypoint sh copilot-cage -c '
    ls -A ~ ; ls ~/.ssh 2>&1 ; printenv | grep -iE "github|token" || echo "no token"
  '
# → empty home, no ~/.ssh, no token. There is nothing to push with.
```

## 7. You apply, commit, and push (outside the cage)

This half runs on your machine, where your credentials live — **you** are the one who presses merge:

```bash
cd ~/work/your-repo
git apply /tmp/agent.patch
git commit -am "fix: sandbox the job runner (reviewed agent diff)"
git push
```

## 8. Verify on GitHub

The commit lands in your repo on github.com. The agent proposed it; you shipped it — and it never held the keys.

---

## Why this is the whole point

- **The agent runs as a stranger, not as you.** Empty home, dropped capabilities, read-only view of your code.
- **It edits a copy, so "read-only" doesn't mean "useless."** You still get real changes — as a diff you control.
- **It can't push because it has no credentials** — that's a consequence of the cage, not a rule you hope it follows.
- **Pushing stays a human step.** The agent proposes; you review and commit.

## Gotchas (learned the hard way)

- **The model has to be good enough to edit.** A ~4B model will leave stray characters or duplicate code. Use ~12B+ (or a dedicated coder) for clean edits.
- **`git` is not in the cage image — on purpose.** Run all `git` commands on the host. The diff comes from the host-mounted working copy.
- **`host.containers.internal`** is how the container reaches a model server running on your host (Podman/Docker on macOS).
- Use `cp -r` (not `cp -a`) for the working copy — `-a` tries to preserve timestamps onto tmpfs and warns.
- **Next wall:** lock the cage's network egress too (allow only your model + approved hosts), so a prompt-injected agent can't reach out even if it tries.
