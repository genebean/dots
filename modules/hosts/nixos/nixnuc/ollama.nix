# Local LLM backend for Hindsight's gene-personal bank (fact
# extraction/mental-model refresh) — avoids depending on the owner's
# ChatGPT/Codex subscription quota for this background task. CPU-only
# (nixnuc has no GPU; services.ollama.package defaults to ollama-cpu when
# neither rocmSupport nor cudaSupport is set, which is the case here).
#
# host = "0.0.0.0": needed for two independent reasons — the gene-personal
# app container reaches this over podman's bridge network
# (hindsight-gene-personal-net) via podman's host.containers.internal, and
# it's also wanted on the LAN directly for other future uses. Binding to
# 127.0.0.1 only would break both. Firewall opening goes through
# genebean.ports (ports.nix), not services.ollama.openFirewall directly —
# this host's own convention, wired generically in default.nix.
{ config, ... }:
{
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    loadModels = [ "qwen2.5:7b-instruct" ];
    port = config.genebean.ports.ollama.port;
  };

  # Real testing showed nixnuc has very little spare RAM (~450MB free
  # baseline before ollama even loads a model) — this host runs a lot of
  # other production services already. These limits make ollama itself the
  # thing that gets squeezed/killed under memory pressure, never a sibling
  # service: MemoryHigh throttles new allocations (backpressure — new
  # inference requests slow down/queue) well before the hard MemoryMax
  # kill, and OOMScoreAdjust makes ollama the kernel's preferred victim over
  # postgresql/forgejo/etc. in a genuine system-wide OOM. Revisit once this
  # workload moves to dedicated hardware with real headroom.
  #
  # CPUQuota/CPUWeight added after real testing showed the same problem on
  # the CPU side: a live inference pinned ollama at 338% CPU, and basic SSH
  # commands to nixnuc started hanging shortly after — 8-core host, capping
  # at 400% leaves half the machine schedulable for everything else even at
  # ollama's peak. CPUWeight (default 100) additionally makes ollama yield
  # proportionally more under contention even within that cap, not just
  # hard-stop at it.
  systemd.services.ollama.serviceConfig = {
    CPUQuota = "400%";
    CPUWeight = 50;
    MemoryHigh = "6G";
    MemoryMax = "8G";
    OOMScoreAdjust = 500;
  };
}
