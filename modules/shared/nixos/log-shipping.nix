# Ships this host's systemd journal to the fleet's VictoriaLogs instance
# (star1, VLAN 2331) via Vector -> pigate's /logsink - the same shape as
# vmagent's /remotewrite path for metrics (see
# modules/hosts/nixos/star1/containers/victorialogs.nix and
# modules/hosts/nixos/pigate/default.nix's monitoring.${home_domain}
# vhost). Every host goes through pigate uniformly, including star1
# itself - no direct-to-container shortcut for anything, one access path
# to reason about.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  home_domain = "home.technicalissues.us";
  # Same literal settings vector's own module would generate into the Nix
  # store itself (services.vector's ExecStart does this internally too) -
  # built here as well so systemd.services.vector's ExecStart override
  # below has something to envsubst from. Still contains the literal
  # ${LOGSHIPPER_PASSWORD} placeholder, unresolved - vector's module
  # doesn't expose its own copy of this derivation as an option.
  vectorConfigTemplate =
    (pkgs.formats.toml { }).generate "vector.toml"
      config.services.vector.settings;
in
{
  services.vector = {
    enable = true;
    journaldAccess = true;

    settings = {
      sinks.victorialogs = {
        auth = {
          password = "\${LOGSHIPPER_PASSWORD}";
          strategy = "basic";
          user = "logshipper";
        };
        compression = "gzip";
        encoding.codec = "json";
        framing.method = "newline_delimited";
        # VictoriaLogs' insert endpoint doesn't answer vector's generic GET
        # healthcheck probe - without this, vector marks the sink
        # permanently unhealthy at startup even though real POSTs work fine.
        healthcheck.enabled = false;
        inputs = [ "journald" ];
        type = "http";
        # Field names and _stream_fields match VictoriaLogs' own vector
        # ingestion docs example exactly:
        # https://docs.victoriametrics.com/victorialogs/data-ingestion/vector/
        uri = "https://monitoring.${home_domain}/logsink?_stream_fields=host,_SYSTEMD_UNIT&_msg_field=message&_time_field=timestamp";
      };

      sources.journald.type = "journald";
    };

    # The sink's auth.password above is written as a literal
    # ${LOGSHIPPER_PASSWORD} placeholder, not a real secret - confirmed
    # live (captured vector's own outgoing Authorization header in an
    # isolated test) that vector does NOT interpolate ${VAR} syntax
    # inside sink auth fields at runtime, despite looking exactly like
    # its documented env-var interpolation; it sends the placeholder
    # text itself, verbatim, as the password. vector's own build-time
    # config check (`vector validate --no-environment`) also can't see
    # this placeholder as a real value, so that check is disabled below
    # too - not catching a real config mistake, just consistent with the
    # fact that this file is never meant to be used as-is (see
    # systemd.services.vector's ExecStart override, which renders the
    # real password in via envsubst before vector ever reads this file).
    validateConfig = false;
  };

  sops.secrets.logshipper_env = {
    # Matches vmagent_push_pw's own restartUnits for the same reason
    # (star1/monitoring.nix, pigate/default.nix): vector reads this once
    # via EnvironmentFile at process start, so rotating the password
    # without this would leave vector running with the old credential -
    # silently failing every /logsink push with 401s - until something
    # else happened to restart it. star1 also appends its own
    # container@star1-syslog-vector.service to this same option from
    # containers/syslog-vector.nix (NixOS merges restartUnits lists) -
    # not added here, since this module is imported fleet-wide and that
    # unit only exists on star1.
    restartUnits = [ "vector.service" ];
    sopsFile = ../secrets.yaml;
  };

  systemd.services.vector.serviceConfig = {
    EnvironmentFile = config.sops.secrets.logshipper_env.path;
    # vector doesn't interpolate ${LOGSHIPPER_PASSWORD} itself (see
    # services.vector.settings' sinks.victorialogs.auth.password comment
    # above) - this renders the real value into a RuntimeDirectory copy
    # via envsubst (which does perform real environment-variable
    # substitution, confirmed live) before vector ever starts, then
    # points vector at that rendered copy instead of the Nix-store
    # template. RuntimeDirectory, not StateDirectory (which the module
    # already uses for vector's own data) - this rendered file only
    # needs to exist for the current run, never persisted, never written
    # to the store.
    ExecStart = lib.mkForce ''
      ${pkgs.bash}/bin/bash -c '${pkgs.gettext}/bin/envsubst < ${vectorConfigTemplate} > /run/vector/vector-rendered.toml && exec ${lib.getExe config.services.vector.package} --config /run/vector/vector-rendered.toml --graceful-shutdown-limit-secs ${toString config.services.vector.gracefulShutdownLimitSecs}'
    '';
    RuntimeDirectory = "vector";
  };
}
