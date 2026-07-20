{
  config,
  hostname,
  lib,
  pkgs,
  username,
  ...
}:
{
  boot.tmp = {
    tmpfsSize = "20%";
    useTmpfs = true;
  };

  environment.persistence."/persist" = {
    hideMounts = true;

    # System (non-home) paths: fine with impermanence's root:root default.
    directories = [
      # uid/gid allocations - without this, gene's uid could get reassigned
      # on reboot, breaking ownership of everything else persisted here
      "/var/lib/nixos"
      # No RTC on this Pi, so systemd-timesyncd's own persisted clock file
      # here is what keeps the system clock from starting every single
      # boot at whatever fallback the kernel/image build defaults to
      # (confirmed on hardware: consistently the nixos-raspberrypi image's
      # own build date) until NTP catches up moments later - not just
      # cosmetic log confusion (explains every "up 122 days"/"since March
      # 17" timestamp seen in journalctl all session), but a real window
      # early in every boot where cert/timestamp validation could see the
      # wrong time.
      "/var/lib/systemd/timesync"
      "/var/lib/tailscale"
    ];
    files = [ "/etc/machine-id" ];

    # Everything under gene's home goes through the dedicated per-user
    # submodule (relative paths) instead of top-level directories/files
    # with absolute /home/gene/... paths. This matters beyond style: the
    # per-user submodule sets user/group to gene on every auto-created
    # ancestor directory (/home/gene itself, .cache, .config, ...);
    # top-level entries default those ancestors to root:root, which
    # silently broke anything gene tried to create directly under $HOME
    # (e.g. nix's own per-user profile dir - "Permission denied" on
    # /home/gene/.cache/nix, which cascaded into home-manager failing
    # with "Could not find suitable profile directory").
    users.${username} = {
      directories = [
        ".cache/chromium" # actual browser cache
        ".config/chromium" # profile, cookies, hass-browser_mod device registration
        # genebean.programs.atuin-client (modules/shared/home/general) is
        # enabled fleet-wide. Its local history db AND its sync-server
        # login session/key both live here (not .config/atuin, which
        # home-manager symlinks from the store and needs no persistence
        # of its own) - without this, sync would need a manual `atuin
        # login` again after every reboot.
        ".local/share/atuin"
      ];
      files = [
        # id_ed25519 itself is sops-managed (see default.nix) and
        # intentionally NOT listed here - a whole-directory bind mount
        # for .ssh would race with sops writing into the same directory.
        # known_hosts has no such conflict. mode 0700 matches what ssh
        # requires for the directory (still needs to be set explicitly -
        # the per-user submodule's default is 0755, just with the right
        # owner instead of root).
        {
          file = ".ssh/known_hosts";
          parentDirectory.mode = "0700";
        }
      ];
    };
  };

  # ------------------------------------------------------------------ #
  # / is wiped to tmpfs on every boot (disko.nix: disko.devices.nodev."/").
  # /nix (the store, rebuilt by every `nixos-rebuild switch`) and
  # /persist (the explicit allowlist above) are the only things that
  # survive a reboot - both are real partitions, also declared in
  # disko.nix. Both need to be mounted before most of boot happens.
  # ------------------------------------------------------------------ #
  fileSystems = {
    "/nix".neededForBoot = true;
    "/persist".neededForBoot = true;
  };

  # Backup policy (paths, pre-reinstall-cleanup, kiosk-restic-full-restore
  # wiring) now lives in genebean.services.kiosk-backups - see
  # ./home-gene.nix and modules/genebean/nixos/services/kiosk-backups.nix.
  # What's persisted above survives a reboot (still on the same SD card),
  # but not a card death - only what's backed up via that module does.

  systemd = {
    services = {
      # systemd-tmpfiles-setup.service is a one-shot that runs once, early
      # in boot, and doesn't get a second chance if whatever creates a
      # given directory fresh on tmpfs loses the race against it - nothing
      # re-runs the rules afterward on a plain boot (as opposed to a
      # `nixos-rebuild switch`, which does via systemd-tmpfiles-
      # resetup.service). Confirmed on hardware three separate times now
      # for three different directories ($HOME itself, breaking atuin's
      # interactive search with a bare "Permission denied"; .config,
      # breaking chromium's crash reporter; and
      # /var/lib/systemd/timesync, breaking systemd-timesyncd's own
      # ability to persist its clock file) - always self-resolves
      # instantly with a manual re-run, so it's a boot-ordering race, not
      # the "unsafe path transition" tmpfiles safety block that a couple
      # of these also hit at various points (see sops.age.keyFile's
      # comment in ./default.nix for that one - no ExecStartPre fixes
      # that variant, only avoiding the unsafe ownership pattern in the
      # first place does). The `+` prefix runs this specific command as
      # root regardless of these services' own non-root User=.
      cage-tty1.serviceConfig.ExecStartPre = [
        "+${pkgs.systemd}/bin/systemd-tmpfiles --create"
      ];
      "home-manager-${username}".serviceConfig.ExecStartPre = [
        "+${pkgs.systemd}/bin/systemd-tmpfiles --create"
      ];

      # The shared restic module hardcodes RESTIC_CACHE_DIR to
      # /var/cache/restic-backups-daily (no option exposed to change it),
      # which lands on this host's 512M tmpfs root (disko.nix). That cache
      # holds restic's local index for the *entire* shared repo - every
      # host's snapshots, not just this one's - and filled the tmpfs to
      # 100% from a single manual `restic ls` while testing this backup,
      # confirmed via `du` afterwards. Redirecting it to /persist (real
      # f2fs partition, effectively the whole card minus /nix's 20G) avoids
      # that, and as a side benefit means the index doesn't have to be
      # re-downloaded from scratch after every reboot.
      restic-backups-daily.environment.RESTIC_CACHE_DIR = lib.mkForce "/persist/restic-cache";

      systemd-timesyncd.serviceConfig.ExecStartPre = [
        "+${pkgs.systemd}/bin/systemd-tmpfiles --create"
      ];
    };

    tmpfiles.rules = [
      "d /var/log/journal 0755 root systemd-journal -"
      # writable zsh history file since $HOME/.zsh_history isn't persisted
      "f /tmp/zsh_history_gene 0600 ${username} users -"
      # Something (NixOS's own createHome, ahead of impermanence's own
      # directory-creation script) creates /home/gene as root:root before
      # impermanence gets a chance to set it up with the right owner via
      # its per-user submodule - and impermanence doesn't re-own a
      # directory that already exists. `z` (unlike impermanence's
      # create-if-missing) enforces ownership every boot regardless of who
      # created it first. This is what broke gene creating anything
      # directly under $HOME (nix's own per-user profile dir included),
      # which cascaded into home-manager failing on every boot.
      "z /home/${username} 0700 ${username} users -"
      "z /home/${username}/.cache 0755 ${username} users -"
      "z /home/${username}/.config 0755 ${username} users -"
      # Same root:root staleness as $HOME itself, one level deeper: these two
      # are impermanence-bind-mounted directories (see the users.${username}
      # block above), so they're independently subject to the same
      # create-if-missing-only limitation - chromium's crash reporter
      # (chrome_crashpad_handler) hard-requires being able to mkdir
      # ~/.config/chromium/Crash Reports on every launch, regardless of
      # --user-data-dir, and fails the whole browser process (SIGTRAP) if it
      # can't - confirmed via strace showing mkdirat(...) = -1 EACCES here.
      "z /home/${username}/.cache/chromium 0755 ${username} users -"
      "z /home/${username}/.config/chromium 0755 ${username} users -"
      # Same reasoning, for the atuin state persisted above - .local and
      # .local/share aren't otherwise forced, so cover the whole ancestor
      # chain rather than assume they'll come out right.
      "z /home/${username}/.local 0755 ${username} users -"
      "z /home/${username}/.local/share 0755 ${username} users -"
      "z /home/${username}/.local/share/atuin 0755 ${username} users -"
      # scripts/prep-install-bootstrap.sh pre-seeds this on a fresh install
      # via nixos-anywhere's --extra-files, which (same class of bug as
      # .config's own root:root staleness earlier) creates it root:root -
      # systemd-timesyncd runs as its own dedicated systemd-timesync user
      # and needs write access to actually keep this file's mtime current
      # going forward, not just read it once at boot.
      "z /var/lib/systemd/timesync 0755 systemd-timesync systemd-timesync -"
      "z /var/lib/systemd/timesync/clock 0644 systemd-timesync systemd-timesync -"
      # id_ed25519.pub isn't sensitive and isn't persisted; reconstruct it
      # every boot from the same value private-flake already declares for
      # this host's authorized_keys entries elsewhere, instead of
      # duplicating it via sops or a persisted file.
      "d /home/${username}/.ssh 0700 ${username} users -"
      "f /home/${username}/.ssh/id_ed25519.pub 0644 ${username} users - ${
        config.private-flake.sshKeys.${hostname}.key
      }"
    ];
  };
}
