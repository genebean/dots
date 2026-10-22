{ username, ... }:
{
  environment.etc = {
    "nix/nix.custom.conf".text = ''
      trusted-users = root ${username}

      # Add an include line here for each genebean system-manager module that
      # writes a file under /etc/nix/nix.conf.d/ so Determinate Nix picks it up.
      include /etc/nix/nix.conf.d/genebean-caches.conf
    '';

    # system-manager has no security.sudo-style option of its own (confirmed
    # against its module tree - nix/modules/ only has auto-upgrade, environment,
    # etc, systemd, tmpfiles; no sudo/security module at all), so this goes
    # through the same raw-file escape hatch as nix.custom.conf above. Needed
    # for `system-manager switch --sudo` to run non-interactively - without
    # it, every switch stops for a password prompt. Scoped to the one command
    # it actually runs (confirmed by reading system-manager's own source,
    # crates/system-manager/src/main.rs): `invoke_engine_local` always shells
    # out to `sudo <store-path>/bin/system-manager-engine <args>` - the binary
    # name (ENGINE_BIN = "system-manager-engine") is a fixed constant, only
    # the store-path hash prefix changes per generation, same reasoning as
    # mightymac's existing `/nix/store/*/activate-rs *` deploy-rs rule
    # (modules/hosts/darwin/mightymac/default.nix). mode = "0440" (copy, not
    # the default symlink) - sudo's own strictness about included files, and
    # it's literally this module's own documented example value for exactly
    # this kind of file. No dot in the filename - Debian/Ubuntu's sudoers.d
    # #includedir skips any entry whose name contains one.
    "sudoers.d/system-manager" = {
      mode = "0440";
      text = ''
        ${username} ALL=(root) NOPASSWD: /nix/store/*/bin/system-manager-engine *
      '';
    };
  };
}
