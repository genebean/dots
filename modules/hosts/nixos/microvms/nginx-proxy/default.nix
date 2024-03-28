{ inputs, config, hostname, microvm, pkgs, sops-nix, username,  ... }: {
  microvm = {
    hypervisor = "qemu";
    socket = "control.socket";
    vcpu = 1;
    volumes = [
      {
        #image = "/persist/microvm/${config.networking.hostName}-var.img";
        image = "/tmp/${config.networking.hostName}-var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
    shares = [
      {
        # use "virtiofs" for MicroVMs that are started by systemd
        proto = "9p";
        tag = "ro-store";
        # a host's /nix/store will be picked up so that no
        # squashfs/erofs will be built for it.
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
    ];
  };
}

