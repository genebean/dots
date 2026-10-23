{
  ##########################################################################
  #                                                                        #
  #  CrowdSec - DEFERRED, not enabled. A real deploy (not dry-activate -   #
  #  this class of bug is invisible to dry-activate, which never actually #
  #  starts services) surfaced three distinct bugs in this nixpkgs        #
  #  version's crowdsec/crowdsec-firewall-bouncer modules, confirmed live  #
  #  on nixnuc 2026-10-23, not guessed:                                    #
  #                                                                        #
  #  1. services.crowdsec.localConfig.acquisitions must be set explicitly  #
  #     or crowdsec reads zero data sources (the evaluator warns about     #
  #     this itself). Needs splitting the same way fail2ban-nginx.nix's    #
  #     jails did: nginx's error_log goes to journald (stderr default),    #
  #     access_log falls back to the real file /var/log/nginx/access.log. #
  #                                                                        #
  #  2. crowdsec.service invokes itself with an explicit                   #
  #     `crowdsec -c <nix-store-path>` flag and never populates            #
  #     /etc/crowdsec/config.yaml at all (confirmed by reading the actual  #
  #     pinned module source, not nixpkgs-unstable's current one - this   #
  #     flake's 26.05 commit predates a module rewrite). But              #
  #     crowdsec-firewall-bouncer's registerBouncer script - generated     #
  #     entirely by NixOS, nothing we wrote - calls bare `cscli` with no   #
  #     -c flag, so it looks for /etc/crowdsec/config.yaml and fails with  #
  #     "no such file or directory". A real incompatibility between these  #
  #     two sibling modules on this nixpkgs version. Our own              #
  #     crowdsec-provision.service hit the identical bug and was fixed by  #
  #     extracting crowdsec.service's own ExecStart path via              #
  #     `builtins.match` and passing it to cscli explicitly - the bouncer  #
  #     register script would need the same treatment, but overriding an  #
  #     upstream-generated script to do that is fragile; registering the   #
  #     bouncer manually once via SSH with the explicit -c flag and wiring #
  #     the resulting key through secrets.apiKeyPath is probably the       #
  #     cleaner fix.                                                      #
  #                                                                        #
  #  3. Deeper still: crowdsec.service's OWN ExecStartPre (crowdsec-setup, #
  #     a script the module generates internally) fails outright:         #
  #     `level=fatal msg="loading api client: no API client section in    #
  #     configuration"`. services.crowdsec.settings.lapi.credentialsFile   #
  #     (which feeds api.client.credentials_path) is apparently required   #
  #     but was never set - this module does not appear to bootstrap a    #
  #     working local-API machine registration out of the box the way     #
  #     fail2ban's bundled sshd jail "just works". This is the blocking    #
  #     issue - #1 and #2 are fixable; this one needs real investigation   #
  #     into what services.crowdsec.settings.lapi/api.server actually     #
  #     need to be set to for a single-host, local-only install to start   #
  #     at all.                                                           #
  #                                                                        #
  #  A crash-looping crowdsec.service was live on nixnuc briefly during    #
  #  this investigation (auto-restarting every ~10s) - stopped manually,   #
  #  not left running. Tracked in agents-beads-collaboration-g4f with the  #
  #  CrowdSec rollout's dry-run gating condition (community blocklist      #
  #  off, simulation mode on) - that condition still applies whenever      #
  #  this is picked back up, on top of fixing bugs 1-3 above.             #
  #                                                                        #
  ##########################################################################

  services.crowdsec.enable = false;
}
