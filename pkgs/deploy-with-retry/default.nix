{ pkgs, inputs }:
let
  deploy-rs = inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.deploy-rs;
in
pkgs.writeShellApplication {
  name = "deploy-with-retry";
  runtimeInputs = [
    deploy-rs
    pkgs.nix
    pkgs.openssh
  ];
  text = ''
    target="''${1:?usage: deploy-with-retry .#hostname [extra deploy-rs args...]}"
    shift

    if [[ "$target" == *#* ]]; then
      flake_ref="''${target%%#*}"
      node="''${target##*#}"
    else
      flake_ref="."
      node="$target"
    fi
    [ -z "$flake_ref" ] && flake_ref="."

    for attempt in 1 2; do
      echo "deploy-rs attempt $attempt/2"

      if deploy "$target" "$@"; then
        exit 0
      fi

      if [[ "$attempt" == 2 ]]; then
        exit 1
      fi

      # Reconnect as the same ssh_user/hostname deploy-rs itself resolved
      # for this node (lib/mkDeployNode.nix), not whoever the local shell
      # user happens to be - those can differ per node (e.g. mightymac
      # uses "gene.liverman", everything else defaults to "gene").
      ssh_user=$(nix eval --raw "$flake_ref#deploy.nodes.\"$node\".sshUser")
      ssh_host=$(nix eval --raw "$flake_ref#deploy.nodes.\"$node\".hostname")

      echo "Waiting for SSH on $ssh_user@$ssh_host..."

      until ssh \
        -o BatchMode=yes \
        -o ConnectTimeout=5 \
        -o ConnectionAttempts=1 \
        "$ssh_user@$ssh_host" true 2>/dev/null
      do
        sleep 2
      done
    done
  '';
}
