# AGENTS.md — dots

This is the authoritative agent guide for this repository. It is self-contained
— do not assume any parent or global AGENTS.md is available. For a human-readable
overview of the repo's purpose and layout, see `README.md`. This file covers what
agents need to know that the README does not.

---

## Who You're Working With

The owner is an experienced infrastructure engineer (SRE) who manages Linux
fleets, runs a NixOS homelab, and is comfortable in a terminal. He is **not an
application developer**. When working on application code:

- Comment generously — future maintenance may be done by an agent without full
  context, or by the owner returning to code he didn't write
- Prefer explicit over implicit — avoid patterns that require deep framework
  knowledge to maintain
- Prefer simple over clever — the best solution is the one that's easiest to
  understand six months later
- If something is non-obvious, explain it in a comment at the point of use

---

## What This Repo Is

A multi-system Nix flake that fully manages NixOS hosts, macOS hosts (via
nix-darwin), and home-manager-only Linux machines. Sensitive configuration lives
in a companion **private-flake** at `~/repos/private-flake` — never commit
secrets or private config here.

---

## Infrastructure Preferences

When making architectural or configuration decisions:

- **Self-hosted over cloud** — prefer infrastructure the owner controls over
  third-party SaaS or cloud services
- **Open-source over proprietary** — all else being equal, prefer open-source
- **Self-sovereign data** — avoid patterns where the owner's data is in third-party
  custody unless there is no self-hosted alternative
- **Simple over clever** — the least complex solution that meets the requirements

These are preferences, not absolute rules. External services are fine for
read-only lookups or when self-hosting is genuinely impractical.

---

## Repo Layout (agent-relevant summary)

```
flake.nix                    — inputs, outputs, host wiring
lib/                         — mkNixosHost / mkDarwinHost / mkHomeConfig helpers
modules/
  genebean/                  — reusable namespaced modules (see genebean Module Pattern below)
    home/                    — home-manager modules; options live under genebean.*
    darwin/                  — nix-darwin companion modules (e.g. Homebrew cask wiring)
  hosts/                     - host-specific modules
    nixos/<hostname>/        — per-host NixOS config + hardware + secrets.yaml
    darwin/<hostname>/       — per-host nix-darwin config
    home-manager-only/       — config for hosts running Home Manager only
  shared/                    - reusable modules
    nixos/                   — NixOS modules imported by multiple hosts
    home/general/            — Home Manager defaults for all systems and config for all GUI systems
    home/linux/              — Home Manager config for Linux-specific apps (NixOS and Home Manager only such as Ubuntu)
    files/                   — raw config files managed via xdg.configFile etc.
.claude/skills/              — project-specific Claude Code skills (committed)
```

---

## Host Inventory

| Hostname | Type | Arch | Notes |
|---|---|---|---|
| bigboy | NixOS | x86_64 | ThinkPad P52, daily driver |
| nixnuc | NixOS | x86_64 | Home server, runs most services |
| hetznix01 | NixOS | x86_64 | Hetzner VPS, runs email + matrix, primary VPS |
| hetznix02 | NixOS | aarch64 | Hetzner VPS, build host for Raspberry Pi's |
| kiosk-entryway | NixOS | x86_64 | Lenovo Q190, headless kiosk, WiFi only (`wlp3s0`) |
| kiosk-gene-desk | NixOS | aarch64 | Raspberry Pi 4, headless kiosk, WiFi only (`wlan0`) |
| AirPuppet / Blue-Rock | macOS | x86_64 | nix-darwin managed |
| mightymac | macOS | aarch64 | nix-darwin managed |
| rainbow-planet | home-manager only | x86_64 | Ubuntu, old NixOS config currently commented out in flake |

---

## Build and Deploy Commands

The `nixup` and `nixdiff` aliases abstract away the differences between NixOS,
nix-darwin, and home-manager-only hosts — use them everywhere rather than
invoking the underlying tools directly. Their definitions live in:
- NixOS / home-manager-only Linux: `modules/shared/home/linux/default.nix`
- macOS (nix-darwin): `modules/hosts/darwin/home.nix`

### Check what will change before deploying

```bash
nixdiff   # builds the new config and diffs it against the currently running system
```

### Apply locally

```bash
nixup   # NixOS:            sudo nixos-rebuild switch --flake ~/repos/dots
        # nix-darwin:       darwin-rebuild switch --flake ~/repos/dots
        # home-manager only: home-manager switch --flake ~/repos/dots#gene-x86_64-linux
```

There is also `nixboot` on NixOS hosts to stage a change for the next reboot
without switching immediately.

### Build here, deploy to a remote NixOS host

`nixos-rebuild` is available natively on NixOS hosts but not on home-manager-only
or nix-darwin hosts. When deploying from one of those, bring it in via `nix shell`:

```bash
nix shell nixpkgs#nixos-rebuild -c nixos-rebuild switch \
  --flake .#<hostname> \
  --target-host ssh://<ip-or-hostname> \
  --sudo
```

To only build the closure without activating (useful for checking before committing):

```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

### Build SD card image (kiosk-gene-desk)

```bash
nix build .#packages.aarch64-linux.kiosk-gene-desk-sdImage
```

---

## Secrets Management

All secrets use **sops-nix**. Encrypted `secrets.yaml` files live per-host under
`modules/hosts/nixos/<hostname>/` and shared secrets at `modules/shared/secrets.yaml`.

- Age key derivation: `ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt`
- Key registration: `.sops.yaml` at repo root controls which age keys decrypt which files
- Edit a secret: `sops modules/hosts/nixos/<hostname>/secrets.yaml`

When a secret must be readable by a non-root service user, set `owner` on the
`sops.secrets` entry (e.g. `owner = "wpa_supplicant"` for wifi credentials).
The default is `root:root 0400`.

---

## Private Flake

Sensitive host modules (wifi networks, email accounts, Tailscale keys, etc.) live
in `~/repos/private-flake`. It is a flake input and its modules are passed via
`additionalModules` in `flake.nix`. When diagnosing a host issue, always check
both repos — the private flake often holds the relevant config.

---

## NixOS Module Pattern

When a service has its own repo, the NixOS module lives there — not here:

- The service repo's `flake.nix` exports `nixosModules.default`
- This repo adds the service repo as a flake input and imports the module in the
  relevant host's `additionalModules`
- This keeps deployment config co-located with the code it deploys

When writing NixOS modules:
- Expose typed options with `lib.mkOption` — domain, ports, data directories,
  secrets file path, enable flag
- Use `DynamicUser = true` for systemd services where possible
- Pass secrets via `EnvironmentFile` pointing to a sops-managed path — never
  hardcode secrets
- Add `systemd.tmpfiles.rules` entries to create required directories

### Port Registry

Service ports are managed through a two-level registry rather than scattered
magic numbers:

- `modules/shared/nixos/ports.nix` — defines the `dots.ports` option type and
  declares fleet-wide ports (ssh, http, https, shared service ports). All entries
  default to `openFirewall = false`.
- `modules/hosts/nixos/<hostname>/ports.nix` — host-specific ports plus any
  fleet-wide overrides (e.g. setting `openFirewall = true` for a port only that
  host exposes).

The `openFirewall` flag is not just documentation — hosts that use the registry
wire it directly to `networking.firewall` via `lib.pipe`:

```nix
networking.firewall = {
  allowedTCPPorts = lib.pipe config.dots.ports [
    builtins.attrValues
    (builtins.filter (e: e.openFirewall && e.protocol == "tcp"))
    (map (e: e.port))
  ];
  allowedUDPPorts = lib.pipe config.dots.ports [
    builtins.attrValues
    (builtins.filter (e: e.openFirewall && e.protocol == "udp"))
    (map (e: e.port))
  ];
};
```

Reference ports in config as `config.dots.ports.<name>.port` rather than
hardcoding numbers — this applies everywhere: service configs, nginx proxy
targets, container definitions, and the firewall. When the surrounding attrset
attribute name is already `port`, use `inherit` — statix rules W03/W04
(`manual_inherit` / `manual_inherit_from`) enforce this and will fail the build
if you use the verbose form where `inherit` would work:

```nix
# rejected by statix W04
port = config.dots.ports.grafana.port;

# correct
inherit (config.dots.ports.grafana) port;
```

When adding a service that other hosts need to know about (e.g. a shared API
endpoint referenced across hosts), declare it in the shared registry. When
adding a service local to one host, declare it in that host's `ports.nix`.

---

## genebean Module Pattern

`modules/genebean/` holds reusable, option-driven modules where platform
differences (NixOS / macOS / Ubuntu) are handled inside the module, not at the
call site. The goal is a Puppet-like abstraction: declare what you want once,
and the module figures out how to deliver it on each OS.

### Structure

```
modules/genebean/
  home/                  — home-manager layer (all platforms)
    default.nix          — { imports = [ ... ]; } — add new modules here
    plasma.nix           — genebean.plasma (desktop env, top-level namespace)
    programs/
      askpass.nix        — genebean.programs.askpass
      ghostty.nix        — genebean.programs.ghostty
      wezterm.nix        — genebean.programs.wezterm
    services/
      tailscale.nix      — genebean.services.tailscale
  darwin/                — nix-darwin system layer (macOS only)
    default.nix
    programs/
      ghostty.nix        — adds Homebrew cask when installViaHomebrew = true
      wezterm.nix
    services/
      tailscale.nix      — adds tailscale-app cask
  nixos/                 — NixOS system layer (NixOS only)
    default.nix
    plasma.nix           — enables plasma6, SDDM, KDE packages, xdg portal
    programs/
      askpass.nix        — sets programs.ssh.askPassword
    services/
      tailscale.nix      — configures services.tailscale + sops secret
```

Each `default.nix` is a plain `{ imports = [ ... ]; }` list. **Adding a module
means creating the file and one line in `default.nix` — flake outputs and lib
helpers stay unchanged.**

### Flake outputs and consumption

```nix
homeManagerModules.genebean = ./modules/genebean/home;
darwinModules.genebean      = ./modules/genebean/darwin;
nixosModules.genebean       = ./modules/genebean/nixos;
```

- All three lib helpers import `homeManagerModules.genebean` into the HM module list.
- `mkDarwinHost` additionally imports `darwinModules.genebean` as a nix-darwin system module.
- `mkNixosHost` additionally imports `nixosModules.genebean` as a NixOS system module.

Consumers set options — they never import module files directly.

### Namespacing conventions

Options mirror upstream naming to keep call sites readable:

| Namespace | Use for | Example |
|---|---|---|
| `genebean.programs.<name>` | User-facing applications | `genebean.programs.ghostty` |
| `genebean.services.<name>` | Background services | `genebean.services.tailscale` |
| `genebean.<name>` | Desktop environments and future meta-modules | `genebean.plasma` |

### Platform detection

`genebeanLib` is passed as `extraSpecialArgs` by all three lib helpers and is
available in any home-manager module:

```nix
{ genebeanLib, lib, pkgs, ... }:
```

| Helper | Value | Use for |
|---|---|---|
| `genebeanLib.isNixOS` | `true` in `mkNixosHost`, `false` elsewhere | NixOS vs other Linux |
| `pkgs.stdenv.isDarwin` | stdlib | macOS detection |

`genebeanLib.isNixOS` is set explicitly per builder (not via `builtins.pathExists`)
to keep evaluation pure. Use it as the `default` for platform-varying options:

```nix
installViaNix = lib.mkOption {
  type    = lib.types.bool;
  default = genebeanLib.isNixOS;
};
```

For apps available as both a Nix package and a Flatpak, expose a
`linuxInstallMethod` option:

```nix
linuxInstallMethod = lib.mkOption {
  type    = lib.types.enum [ "flatpak" "nixpkgs" "none" ];
  default = "flatpak";  # or "nixpkgs" if no flatpak exists for this app
};
```

The module then acts on that option rather than installing via both paths.

### Darwin companion modules

When a feature needs a nix-darwin system-level action (e.g. adding a Homebrew
cask or MAS app), create a companion under `modules/genebean/darwin/`. The
companion reads the home-manager option via:

```nix
config.home-manager.users.${username}.genebean.<namespace>.<option>
```

`username` is available as a `specialArg` in all darwin system modules.

### NixOS companion modules

When a feature needs a NixOS system-level action (e.g. enabling a service,
setting system programs, configuring polkit), create a companion under
`modules/genebean/nixos/`. NixOS companions also read the home-manager option
via `config.home-manager.users.${username}.genebean.*` — the consumer only ever
sets the home-manager option, both layers respond automatically.

### Adding a new genebean module

1. **Home layer** — `modules/genebean/home/programs/<name>.nix`:
   define `options.genebean.programs.<name>.*` and
   `config = lib.mkIf cfg.enable { ... }`. Add to `home/default.nix`.

2. **Darwin companion** (if needed) — `modules/genebean/darwin/programs/<name>.nix`:
   read `config.home-manager.users.${username}.genebean.programs.<name>.*`,
   add Homebrew cask/formula/MAS entry. Add to `darwin/default.nix`.

3. **NixOS companion** (if needed) — `modules/genebean/nixos/programs/<name>.nix`:
   read the same HM option path, configure system-level NixOS options.
   Add to `nixos/default.nix`.

4. **Call site** — set `genebean.programs.<name>.enable = true` in `all-gui.nix`,
   a shared module, or a host file. No imports needed.

---

## Code Quality Gates

Before pushing any `.nix` change:

```bash
nix fmt .          # nixfmt-tree — formats all Nix files
nix run .#deadnix  # finds dead code
nix run .#statix   # lints for common issues
```

Pre-commit hooks enforce this automatically after `pre-commit install`. CI
(`.github/workflows/validate.yml`) mirrors the same checks.

**Also run `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel`**
for the affected host before pushing whenever `flake.nix`, `flake.lock`, or a
host module changes. The Nix sandbox is authoritative; remote CI failures are
slow to diagnose.

---

## Commit and PR Hygiene

- Write commit messages as descriptions of what the code **is**, not what changed.
  For non-trivial commits, include a body: one short paragraph per major component
  describing what it does, key decisions, and any non-obvious constraints. A
  subject line alone is not sufficient for features. Reserve before/after framing
  for bug fixes only.
- Incremental local commits are fine as a working tool, but squash before pushing.
  What reaches the remote should reflect the final, complete state of the work.
  Multiple commits in a pushed PR are only justified for genuinely independent
  logical concerns.
- If a follow-up fix is caught after committing (even after pushing), amend
  immediately and silently — use `--force-with-lease` if already pushed.
- After every push that changes what a PR does, update the PR description:
  `gh pr edit <N> --body "..."`. Base it entirely on `git log main..HEAD`.
- When writing `gh pr create` or `gh pr edit` bodies containing backticks, use
  `PREOF` (not `EOF`) as the heredoc delimiter — backticks inside
  `$(cat <<'EOF' ... EOF)` are interpreted as command substitution by the outer
  shell; `PREOF` prevents this.
- Do not bundle unrelated changes in a single commit.

---

## Git Branch Workflow

- Start new work from a fresh main:
  `git checkout main && git pull`, then `git checkout -b <branch-name>`
- Delete merged branches locally after the PR merges: `git branch -d <old-branch>`
- Only rebase when there is actual divergence from main. Check
  `git log --oneline origin/main..HEAD` before opening a PR — if main has not
  moved ahead of your branch base, rebasing rewrites SHAs for no reason.

---

## Skills

Project-specific Claude Code skills live in `.claude/skills/` and are committed
to this repo (`.gitignore` tracks `skills/` but ignores the rest of `.claude/`).
Add new skills there when a workflow is worth automating.

---

## What NOT to Change Without Asking

- `flake.lock` — only update intentionally with `nix flake update [input]`
- `.sops.yaml` — changing key rules requires re-encrypting secrets; confirm before touching
- `system.stateVersion` — must stay at the NixOS version the host was first installed on
- This `AGENTS.md` file itself — propose changes rather than silently editing

---

## NixOS 26.05 — Known Breaking Changes

All hosts are on 26.05 except kiosk-gene-desk (Pi — deployment method TBD).
These notes apply when completing that upgrade or when rebuilding from scratch.

**wpa_supplicant hardening** (affects all WiFi hosts):
- Set `networking.wireless.interfaces = ["<iface>"]` explicitly — auto-detection
  reads `/sys/class/net` which is not mounted in the new hardened sandbox
- Set `owner = "wpa_supplicant"` on the sops wifi_creds secret — the daemon now
  runs unprivileged and cannot read root-owned files
- Service name changes from `wpa_supplicant.service` to
  `wpa_supplicant-<iface>.service` — update `restartUnits` and any `wants`
- Interface names: kiosk-entryway uses `wlp3s0`, kiosk-gene-desk uses `wlan0`

**simple-nixos-mailserver API changes**:
- `mailserver.certificateScheme` removed → use `mailserver.x509.useACMEHost`
- `mailserver.loginAccounts` renamed → `mailserver.accounts`
- `config.services.dovecot2.user` no longer exists → hardcode `"dovecot2"`
