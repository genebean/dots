# modules/genebean

Reusable, option-driven modules that abstract platform differences behind a
single Home Manager interface. The philosophy is Puppet-like: declare what you
want once in Home Manager, and the module figures out how to deliver it on each
platform (NixOS, macOS/nix-darwin, Ubuntu/HM-only).

Consumers set options. They never import module files directly.

---

## Directory Layout

```
modules/genebean/
  data/           — pure Nix data (no module system); imported by any layer that needs it
  home/           — Home Manager (all platforms) — always the consumer declaration point
  darwin/         — nix-darwin system layer (macOS only) — e.g. Homebrew casks
  nixos/          — NixOS system layer (NixOS only) — e.g. system services, polkit
  system-manager/ — system-manager layer (HM-only Linux hosts) — e.g. /etc files
```

Each module layer has a `default.nix` that is a plain `{ imports = [ ... ]; }` list.
Adding a module means creating the file and one line in `default.nix` — no
changes to flake outputs or lib helpers are needed.

### How the module layers are loaded

| Layer | Loaded by | Via |
|---|---|---|
| `home/` | all builders | `homeManagerModules.genebean` in every lib helper |
| `darwin/` | `mkDarwinHost` only | `darwinModules.genebean` as a nix-darwin system module |
| `nixos/` | `mkNixosHost` only | `nixosModules.genebean` as a NixOS system module |
| `system-manager/` | `mkSystemConfig` only | `systemManagerModules.genebean` as a system-manager module |

Home Manager is always the consumer-facing layer. The other layers are
implementation details that fire automatically — the user only ever sets
the home-manager option.

### The `data/` directory

`data/` holds plain Nix attrsets — no module system, no options, no `lib` or
`pkgs`. Think Puppet Hiera: structured data that any module layer can import
directly and use however its module system requires.

```nix
# data/nix-caches.nix — just an attrset
{
  substituters = [ "https://cache.example.com" ];
  trustedPublicKeys = [ "example.com-1:..." ];
}
```

Use `data/` when the same values need to reach multiple module systems that
cannot share options (e.g. NixOS `nix.settings`, nix-darwin `nix.settings`,
and system-manager `environment.etc`). Defining the data once and importing it
avoids drift between layers.

Candidates for `data/`:
- Fleet-wide Nix binary caches (`nix-caches.nix`) — already here
- Port/service registry (`ports.nix`) — currently in `nixos/`, candidate for future move

---

## Namespacing

| Namespace | Use for | Example |
|---|---|---|
| `genebean.programs.<name>` | User-facing applications | `genebean.programs.ghostty` |
| `genebean.services.<name>` | Background services | `genebean.services.tailscale` |
| `genebean.<name>` | Meta / environment (desktop, kiosk hardware) | `genebean.plasma` |

Top-level options like `genebean.plasma` and `genebean.kiosk-hardware` don't
fit neatly into programs or services — they configure entire environments rather
than individual pieces of software.

---

## `genebeanLib` Flags

Passed as `extraSpecialArgs` to every Home Manager module. All default `false`;
one is set `true` per builder:

| Flag | True in | Use for |
|---|---|---|
| `isNixOS` | `mkNixosHost` | NixOS-specific defaults and guards |
| `isDarwin` | `mkDarwinHost` | macOS-specific defaults and guards |
| `isHMOnly` | `mkHomeConfig` | Ubuntu / HM-only hosts |

Set explicitly per builder (not via `builtins.pathExists`) to keep evaluation
pure.

---

## Patterns

### 1. Simple enable stub

The home module declares the option; all install work happens in the companions.

```nix
{ lib, ... }:
{
  options.genebean.programs.foo = {
    enable = lib.mkEnableOption "Foo";
  };
}
```

### 2. Self-contained with platform guards

The home module handles everything, gating platform-specific config with
`lib.optionalAttrs` and `genebeanLib` flags.

```nix
config = lib.mkIf cfg.enable (
  lib.optionalAttrs (!genebeanLib.isDarwin) {
    services.flatpak.packages = [ "org.example.Foo" ];
  }
);
```

### 3. `linuxInstallMethod` enum

For apps available as both a Flatpak and a Nix package on Linux.

```nix
linuxInstallMethod = lib.mkOption {
  type    = lib.types.enum [ "flatpak" "nixpkgs" "none" ];
  default = "flatpak";
};
```

The module then acts on the choice rather than installing via both paths.

### 4. Dual install flags

For apps that have separate Homebrew and Nix install paths (e.g. Ghostty).

```nix
installViaHomebrew = lib.mkOption {
  type    = lib.types.bool;
  default = pkgs.stdenv.isDarwin;
};
installViaNix = lib.mkOption {
  type    = lib.types.bool;
  default = genebeanLib.isNixOS;
};
```

### 5. Darwin companion

When macOS needs a system-level action (Homebrew cask, MAS app), the companion
reads the home-manager option:

```nix
# darwin/programs/foo.nix
{ config, lib, username, ... }:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.foo.installViaHomebrew {
    homebrew.casks = [ "foo" ];
  };
}
```

### 6. NixOS companion

When NixOS needs a system-level action (service, polkit, system program), the
companion reads the same home-manager option path:

```nix
# nixos/programs/foo.nix
{ config, lib, username, ... }:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.foo.enable {
    programs.foo.enable = true;
  };
}
```

### 7. Data-driven cross-layer module

When the same values must reach multiple module systems that cannot share
options (e.g. NixOS, nix-darwin, and system-manager all need the same cache
list but set it via different options), put the data in `data/` and import it
in each layer:

```nix
# nixos/nix-caches.nix and darwin/nix-caches.nix
let caches = import ../data/nix-caches.nix; in
{ ... }:
{ nix.settings = { extra-substituters = caches.substituters; ... }; }

# system-manager/nix-caches.nix
let caches = import ../data/nix-caches.nix; in
{ ... }:
{ environment.etc."nix/nix.conf.d/genebean-caches.conf".text =
    builtins.concatStringsSep "\n" (
      map (s: "extra-substituters = ${s}") caches.substituters
      ++ map (k: "extra-trusted-public-keys = ${k}") caches.trustedPublicKeys
    ) + "\n"; }
```

Do **not** expose data-driven cross-layer values as Home Manager options — the
system-manager layer cannot read HM options, so duplicating them there would
create drift.

---

## Adding a New Module

1. **Home layer** — `home/programs/<name>.nix` (or `services/` as appropriate):
   define `options.genebean.programs.<name>.*` and
   `config = lib.mkIf cfg.enable { ... }`. Add to `home/default.nix`.

2. **Darwin companion** (only if a system-level macOS action is needed) —
   `darwin/programs/<name>.nix`. Add to `darwin/default.nix`.

3. **NixOS companion** (only if a system-level NixOS action is needed) —
   `nixos/programs/<name>.nix`. Add to `nixos/default.nix`.

4. **system-manager module** (only if a system-level action is needed on
   HM-only Linux hosts) — `system-manager/<name>.nix`. Add to
   `system-manager/default.nix`.

5. **Call site** — set `genebean.programs.<name>.enable = true` in the relevant
   shared module or host file. No imports needed.

Not every module needs all layers. Most GUI apps have a home layer and a darwin
companion; NixOS/system-manager layers are only needed when the system layer
must act (e.g. enabling a service, writing an `/etc` file).
