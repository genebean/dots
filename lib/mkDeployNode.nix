{ inputs, ... }:
{
  mkDeployNode =
    {
      hostname, # matches nixosConfigurations.<hostname> (or darwinConfigurations.<hostname> when darwin = true); also used as-is for SSH, resolved via Tailscale MagicDNS
      system,
      fastConnection,
      remoteBuild,
      darwin ? false,
      sshUser ? "gene", # mkDarwinHost defaults to "gene" too, but some darwin hosts (mightymac, Blue-Rock) override username to "gene.liverman" - pass that through explicitly for those nodes
    }:
    {
      inherit hostname sshUser;
      inherit fastConnection remoteBuild;
      profiles.system = {
        user = "root";
        path =
          if darwin then
            inputs.deploy-rs.lib.${system}.activate.darwin inputs.self.darwinConfigurations.${hostname}
          else
            inputs.deploy-rs.lib.${system}.activate.nixos inputs.self.nixosConfigurations.${hostname};
      };
    };
}
