{ config, pkgs, ... }:
{
  systemd.services.zfs-create-orico-datasets = {
    description = "Create orico ZFS datasets";
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    before = [
      # Legacy ZFS mount units (datasets must exist before mount happens)
      "var-lib-audiobookshelf.mount"
      "var-lib-postgresql.mount"
      "var-lib-postgresql-16-pg_wal.mount"
      # NixOS services with orico state dirs
      "dolt-beads.service"
      "forgejo.service"
      "immich-server.service"
      "jellyfin.service"
      "nextcloud-setup.service"
      "pinchflat.service"
      "postgresql.service"
      # Explicit because DefaultDependencies is off (see unitConfig below)
      "shutdown.target"
    ]
    # Dynamically include every OCI container's systemd service unit so new
    # containers are automatically covered without editing this file.
    # c.serviceName comes from virtualisation.oci-containers.containers.<name>.serviceName
    # and resolves to e.g. "podman-photon" for a container named "photon".
    ++ map (c: "${c.serviceName}.service") (
      builtins.attrValues config.virtualisation.oci-containers.containers
    );
    after = [ "zfs-import-orico.service" ];
    conflicts = [ "shutdown.target" ];
    # This unit has to run in early boot: the legacy ZFS mounts listed in
    # `before` belong to local-fs.target, which sysinit.target waits for. A
    # normal service is implicitly After=sysinit.target, which closes the loop
    # (sysinit -> local-fs -> mount -> this unit -> sysinit). systemd breaks
    # that at boot, but switch-to-configuration cannot: any deploy that
    # restarts sysinit-reactivation.target (e.g. a rebuilt systemd) fails with
    # "Failed to start sysinit.target: Transaction order is cyclic" and
    # deploy-rs rolls back. These are the same dependency settings NixOS uses
    # for its own zfs-import-<pool> units.
    unitConfig.DefaultDependencies = false;
    script =
      let
        zfs = "${pkgs.zfs}/bin/zfs";
        datasets = [
          "orico/audiobookshelf"
          "orico/dolt-beads"
          "orico/forgejo"
          "orico/immich"
          "orico/jellyfin"
          "orico/mountain-mesh-bot-discord"
          "orico/nextcloud"
          "orico/photon"
          "orico/pinchflat"
          "orico/postgresql-data"
          "orico/postgresql-wal-16"
          "orico/psitransfer"
          "orico/rustfs"
        ];
      in
      builtins.concatStringsSep "\n" (
        map (d: "${zfs} list ${d} >/dev/null 2>&1 || ${zfs} create -p ${d}") datasets
      );
  };
}
