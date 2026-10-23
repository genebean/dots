{

  ##########################################################################
  #                                                                        #
  #  Linux audit framework: a tamper-evident record of what actually      #
  #  happened on this host (who read/wrote identity files, who ran sudo/  #
  #  su), as the forensic complement to fail2ban/CrowdSec's "stop it      #
  #  before it lands" layer - this one answers "it landed anyway, what    #
  #  did they touch". Deliberately kept to a low-noise baseline (CIS-     #
  #  benchmark-style identity/privilege watches) rather than broad exec   #
  #  tracing, which would flood the log with every root-owned systemd     #
  #  service's normal activity.                                          #
  #                                                                        #
  #  Logs are LOCAL ONLY for now - an attacker with root can wipe them -  #
  #  until the planned star1 observability stack (Tempo/Loki) exists to   #
  #  ship them off-host. Tracked in agents-beads-collaboration-g4f.       #
  #                                                                        #
  ##########################################################################

  security.audit = {
    enable = true;
    rules = [
      # Identity and privilege files
      "-w /etc/passwd -p wa -k genebean-identity"
      "-w /etc/shadow -p wa -k genebean-identity"
      "-w /etc/group -p wa -k genebean-identity"
      "-w /etc/gshadow -p wa -k genebean-identity"
      "-w /etc/sudoers -p wa -k genebean-identity"
      "-w /etc/sudoers.d -p wa -k genebean-identity"

      # SSH daemon config changes
      "-w /etc/ssh/sshd_config -p wa -k genebean-sshd"

      # sudo/su invocation (scoped to the two binaries, not a blanket
      # euid=0 execve watch - that would log every root-owned service's
      # normal execs, not just human privilege escalation)
      "-w /run/wrappers/bin/sudo -p x -k genebean-sudo"
      "-w /run/wrappers/bin/su -p x -k genebean-sudo"
    ];
  };

  security.auditd.enable = true;
}
