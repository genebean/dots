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
      "forgejo.service"
      "immich-server.service"
      "jellyfin.service"
      "nextcloud-setup.service"
      "pinchflat.service"
      "postgresql.service"
    ]
    # Dynamically include every OCI container's systemd service unit so new
    # containers are automatically covered without editing this file.
    # c.serviceName comes from virtualisation.oci-containers.containers.<name>.serviceName
    # and resolves to e.g. "podman-photon" for a container named "photon".
    ++ map (c: "${c.serviceName}.service") (
      builtins.attrValues config.virtualisation.oci-containers.containers
    );
    after = [ "zfs-import-orico.service" ];
    script =
      let
        zfs = "${pkgs.zfs}/bin/zfs";
        datasets = [
          "orico/audiobookshelf"
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
        ];
      in
      builtins.concatStringsSep "\n" (
        map (d: "${zfs} list ${d} >/dev/null 2>&1 || ${zfs} create -p ${d}") datasets
      );
  };
}
