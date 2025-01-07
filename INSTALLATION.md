## Installing on aarch64-linux

1. set password
2. create a temp ubuntu server if this is the first aarch64 host and ssh into it: `ssh -o UserKnownHostsFile=/dev/null root@<ip of temp host>`
3. `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
4. `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`
5. Run these commands:
   ```bash
   read -s SSHPASS
   export SSHPASS=$SSHPASS
   export TARGET_HOST=hetznix02
   export DOTS_BRANCH=pi-setup
   nix --extra-experimental-features 'flakes nix-command' run github:nix-community/nixos-anywhere -- --env-password --flake github:genebean/dots/${DOTS_BRANCH}#${TARGET_HOST} --target-host nixos@195.201.224.89
   ```
6. Delete temp server
7. 