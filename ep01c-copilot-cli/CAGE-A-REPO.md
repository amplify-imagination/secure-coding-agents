# Cage GitHub Copilot CLI against a real repo — full walkthrough

Let an AI coding agent work on a real Git repo while it **cannot touch your real files, your keys, or your network, and can't push anything**. The agent works on a throwaway copy and proposes a diff. *You* review it, apply it, and push — from outside the cage, where your credentials live.

Every command here is verified on macOS (Apple Silicon) with rootless Podman. It works the same on Linux.

```
clone ─► cage builds: read-only repo + throwaway copy + sealed network + relay-to-model only
      └─► caged agent proposes a diff (writes nothing) ─► you apply + commit + push ─► GitHub
            your real repo stays read-only           your keys never enter the box
```

---

## What you need (one-time)

- **Podman** (rootless) — `brew install podman && podman machine init && podman machine start`
- **A local model server** — [LM Studio](https://lmstudio.ai). Load a coder model and start its server on `:1234`. A dedicated coder like **Qwen2.5-Coder-7B** (used in the video) makes clean, reliable proposals; give it a 32k context window. A ~4B model will mangle edits.
- **The cage image** — built below. It bundles **Node + the Copilot CLI and nothing else** — no `git`, no SSH, no credentials. That's what makes "the agent can't push" true by construction.

> Copilot runs in **BYOK** (bring-your-own-key) mode pointed at your local model, so it needs **no GitHub login**.

---

## 0. Build the cage image (once)

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

## 1. Start your local model

In LM Studio, load a coder model and start its server, then confirm it's up:

```bash
curl -s http://localhost:1234/v1/models   # note the model id it advertises
```

`cage` reads the model id from the server automatically — you never hardcode it.

---

## 2. Run it: one command

```bash
./cage example-repo
```

That single command raises every wall and drops you into the caged agent. Here is exactly what `cage` does, and why each part matters:

| Wall | How `cage` builds it |
|---|---|
| **Read-only repo** | mounts your repo at `/src:ro` — the agent can read it, never change it |
| **Throwaway copy** | `cp -r` your repo to `~/.cage/<repo>-work`, mounted writable at `/work` — the only thing it can write to |
| **Empty home** | `--tmpfs /home/agent` — no dotfiles, no SSH key, no token to find |
| **No powers** | `--cap-drop=ALL` — every Linux capability dropped |
| **Local brain, offline** | `COPILOT_PROVIDER_BASE_URL` → your model via the relay; `COPILOT_OFFLINE=true` |
| **Sealed network** | runs on `cage-noegress`, an `--internal` Podman network with **no route out** |
| **One allowed exit** | a relay container forwards **only** to your model — see below |

---

## 3. The network wall (the part most people skip)

A `--cap-drop` flag is easy. The network is the wall that takes two moves, so `cage` builds it for you:

```bash
# 1) a sealed network with no route out
podman network create --internal cage-noegress

# 2) a relay that forwards ONLY to your model — the single open door
podman run -d --name cage-modelproxy --network cage-noegress --network podman \
  -v ./relay.js:/relay.js:ro --entrypoint node copilot-cage /relay.js
```

The entire allowlist is `relay.js` — seven lines that pipe to one address and nowhere else:

```js
const net = require("net");
const [LPORT, RHOST, RPORT] = [1234, "host.containers.internal", 1234]; // the model, period
net.createServer(c => {
  const u = net.connect(RPORT, RHOST);
  c.pipe(u); u.pipe(c);
  u.on("error", () => c.destroy()); c.on("error", () => u.destroy());
}).listen(LPORT);
```

**Prove it** — from *inside* the sealed network, the model answers and the open internet does not:

```bash
podman run --rm --network cage-noegress -v ./probe.js:/probe.js:ro \
  --entrypoint node copilot-cage /probe.js
#  the model (via relay)   reachable   HTTP 200
#  the open internet       blocked     ENOTFOUND
#  github.com              blocked     ENOTFOUND
```

Enforcement is by **routing, not a firewall**: there is simply no path out except the relay. To allow an approved tool host later, add another relay — nothing else gets out.

---

## 4. Talk to the agent

Inside the session, tell it exactly what you want. With a small local model, a specific ask beats a vague one:

```
run_job in runner.py uses os.system, which is unsafe.
Propose a minimal, safe diff — show me the change, don't rewrite anything else.
```

It reasons over the read-only code and **proposes a diff**. In propose mode it writes nothing — `Changes +0 -0` is correct, not a failure. The proposal is yours to judge.

> Prefer it to write the change to the copy instead? Ask it to, then diff the copy on the host:
> `git -C ~/.cage/example-repo-work diff`

---

## 5. Prove it can't push (no keys in the box)

```bash
podman run --rm --userns=keep-id --tmpfs /home/agent --env HOME=/home/agent \
  --cap-drop=ALL --entrypoint sh copilot-cage -c '
    ls -A ~ ; ls ~/.ssh 2>&1 ; printenv | grep -iE "github|token" || echo "no token"
  '
# → empty home, no ~/.ssh, no token. There is nothing to authenticate with.
```

The inability to push is a property of the cage, not a rule you're trusting the agent to follow.

---

## 6. You apply, commit, and push (outside the cage)

This half runs on your machine, where your credentials live — **you** are the one who ships:

```bash
cd example-repo
git apply <the-proposed-diff>
git commit -am "fix: sandbox the job runner (reviewed agent proposal)"
git push
```

The commit lands on GitHub. The agent proposed it; you shipped it — and it never held the keys.

---

## Why this is the whole point

- **The agent runs as a stranger, not as you** — empty home, dropped capabilities, read-only view of your code.
- **It edits a copy, so "read-only" still gets real work done** — you get changes as a diff you control.
- **It can't reach the internet and can't push** — both are consequences of the cage, not promises.
- **Shipping stays a human step.** The agent proposes; you review and commit.

## Gotchas (learned the hard way)

- **Use a coder model.** Qwen2.5-Coder-7B gives clean proposals; a ~4B model leaves stray characters.
- **Be specific.** A small local model anchors far better on "run_job uses os.system — propose a safe diff" than on "make it safer."
- **`git` is not in the cage image — on purpose.** Run all `git` on the host.
- **`host.containers.internal`** is how the relay reaches your host's model server (Podman/Docker).
- **Never mount the Docker/Podman socket into the cage.** A socket mount equals host root — it hands the agent exactly the escape this cage exists to prevent.

## Optional walls (in this repo)

- `hooks/cage-hook.sh` + `hooks/cage.json` — a **preToolUse camera**: logs every tool call and can deny it.
- `litellm_config.yaml` — a **budget gateway** that refuses past a hard spend cap.

These aren't required for the loop above; they're the camera and cost walls from the series.
