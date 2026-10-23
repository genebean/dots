{ config, ... }:
{

  ##########################################################################
  #                                                                        #
  #  CrowdSec, DRY-RUN ONLY - do not flip this to enforcing without       #
  #  re-reading agents-beads-collaboration-g4f first.                     #
  #                                                                        #
  #  The repo owner was burned by CrowdSec years ago: it locked out       #
  #  legitimate traffic almost immediately. The most likely cause was     #
  #  the community blocklist - bans made by OTHER people's CrowdSec       #
  #  installs, pulled in automatically via the Central API, so a noisy    #
  #  scenario on a stranger's host could ban a shared IP range (VPN       #
  #  exit, CGNAT, cloud NAT) that affected us too. Two deliberate         #
  #  decisions below exist specifically to not repeat that:              #
  #                                                                        #
  #    1. We never run `cscli capi register`, so this install has no      #
  #       Central API credentials and never pulls the community          #
  #       blocklist - only local scenarios (this host's own logs) feed    #
  #       decisions.                                                      #
  #    2. `cscli simulation enable` (no scenario argument = global) is    #
  #       run as part of provisioning below. CrowdSec's own documented    #
  #       simulation mode marks every decision as simulated; a compliant  #
  #       bouncer logs what it WOULD have blocked without touching the    #
  #       firewall. This is the correct place to toggle that - not a      #
  #       guessed bouncer-level flag.                                     #
  #                                                                        #
  #  Collections installed are deliberately narrow (linux, sshd, nginx)   #
  #  to match what's actually running - add more only alongside whatever  #
  #  new log source needs it.                                             #
  #                                                                        #
  #  Decisions/alerts from this dry-run live only in CrowdSec's local      #
  #  SQLite DB (`cscli decisions list` / `cscli alerts list`) until the   #
  #  planned star1 observability stack (Tempo/Loki) exists to ship them   #
  #  somewhere durable. Tracked in agents-beads-collaboration-g4f.        #
  #                                                                        #
  ##########################################################################

  services.crowdsec = {
    enable = true;

    # Without this, crowdsec starts but reads nothing - confirmed by the
    # evaluator's own warning ("CrowdSec will not look for any data
    # source") the first time this module was added without it. Split the
    # same way the fail2ban-nginx.nix jails had to be, for the same
    # confirmed reason: nginx's error_log defaults to "stderr" (journald),
    # while its access_log has no override and falls back to the real file
    # at /var/log/nginx/access.log.
    localConfig.acquisitions = [
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
        labels.type = "syslog";
      }
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=nginx.service" ];
        labels.type = "nginx";
      }
      {
        filenames = [ "/var/log/nginx/access.log" ];
        labels.type = "nginx";
      }
    ];
  };

  services.crowdsec-firewall-bouncer = {
    enable = true;
    registerBouncer.enable = true;
  };

  systemd.services.crowdsec-provision = {
    description = "Install CrowdSec hub collections and enable global simulation (dry-run) mode";
    after = [ "crowdsec.service" ];
    wants = [ "crowdsec.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # All three cscli calls are idempotent - safe to re-run every boot.
    script = ''
      ${config.services.crowdsec.package}/bin/cscli hub update
      ${config.services.crowdsec.package}/bin/cscli collections install crowdsecurity/linux crowdsecurity/sshd crowdsecurity/nginx
      ${config.services.crowdsec.package}/bin/cscli simulation enable
    '';
  };
}
