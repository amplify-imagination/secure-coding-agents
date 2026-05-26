# Free tools to cage an AI coding agent — by risk

Capability-first: the four capabilities (empty home · repo read-only · no creds in env · network off or tight allowlist) are the point. Pick the tool by how much damage the agent could do, not by paranoia.

## Tier 1 — advisory / low-risk (summarizes, suggests; can't touch much)
*Fast, light, zero friction.*
- **Dev Containers** (free) — a `.devcontainer` runs the agent in a container with only the repo mounted.
- **GitHub Codespaces** (free monthly hours) — a disposable cloud dev box.
- **bubblewrap** (free, rootless, no daemon) — the zero-setup option used in this repo's demos.

## Tier 2 — assistive / writes code, runs commands
*Real containment without killing DX.*
- **Podman** (free, rootless by default) — cleanest free Docker alternative.
- **Docker** (free for personal & small business) — use rootless mode.
- **Egress allowlist** — run on a custom network; permit the package registry + your git host only (`--network none` when nothing's needed). A free proxy (tinyproxy / mitmproxy) gives a real allowlist.

## Tier 3 — autonomous / can deploy, touch prod
*Assume hostile-by-accident; cage everything.*
- **gVisor** (free) — userspace-kernel sandboxed runtime; much stronger than vanilla containers.
- **Firecracker microVMs** (free) — true VM isolation at near-container speed.
- **Kata Containers** (free) — containers backed by lightweight VMs.
- **Ephemeral VMs** (free) — `Lima`/`Colima` (macOS), `multipass`, `UTM`/`tart`: spin a throwaway VM, run the agent, destroy it.

## The rule
Don't put Tier 3 on everything — over-lock the harmless stuff and developers route around you. **Match the cage to the blast radius.**

*(Free terms and capabilities change — verify before relying on them.)*
