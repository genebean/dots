# Local LLM backend for Hindsight's gene-personal bank (fact
# extraction/mental-model refresh) - moved here from nixnuc once this host
# existed, specifically to get out from under nixnuc's tight resource
# constraints (see git history on nixnuc/ollama.nix for the full story -
# that host measured ~450MB free RAM baseline and 338% CPU during
# inference, needing hard caps to avoid starving its many other services).
# This host has neither problem: 62Gi RAM, 16 threads, and essentially
# nothing else running on it yet.
#
# host = "0.0.0.0": nixnuc's gene-personal Hindsight container reaches this
# over the LAN (this host's reserved IP), not podman's
# host.containers.internal (that only resolves the host a container is
# actually running on). Firewall opening goes through genebean.ports
# (ports.nix), not services.ollama.openFirewall directly - this fleet's own
# convention, wired generically in default.nix.
{ config, ... }:
{
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    loadModels = [ "qwen2.5:7b-instruct" ];
    port = config.genebean.ports.ollama.port;
  };

  # No MemoryHigh throttling here, unlike nixnuc's version - there's nothing
  # else on this host to protect from memory contention right now.
  # MemoryMax alone is just basic hygiene (stop a genuinely runaway model
  # load from taking the whole box down), set well under the real 62Gi total
  # to leave headroom for whatever else lands on this host later.
  #
  # CPUQuota is still set, though - 16 threads, capped at 14 (1400%), so SSH
  # and everything else stays responsive even at Ollama's inference peak,
  # rather than reserving it just to protect sibling services like nixnuc's
  # did. CPUWeight makes it yield proportionally under contention even
  # within that cap, not just hard-stop at it.
  systemd.services.ollama.serviceConfig = {
    CPUQuota = "1400%";
    CPUWeight = 50;
    MemoryMax = "48G";
  };
}
