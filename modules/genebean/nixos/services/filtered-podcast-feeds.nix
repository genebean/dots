# Republishes an upstream podcast RSS feed with only the episodes matching a
# text filter (and optionally a since-date), so e.g. a family member's
# Audiobookshelf/Absorb setup can subscribe to just the arc of a show they
# care about instead of the whole back-catalog. Each attribute name under
# `feeds` becomes the generated file's slug: <stateDir>/<slug>.xml. This
# module only writes those files - it does not touch nginx. The host is
# responsible for serving <stateDir> (e.g. via an nginx alias) at whatever
# hostname/path matches `publicUrl`, and for any auth in front of it. The
# generator itself lives at pkgs/filtered-podcast-feeds.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.genebean.services.filteredPodcastFeeds;

  stateDir = "/var/lib/filtered-podcast-feeds";

  feedType = types.submodule {
    options = {
      source = mkOption {
        type = types.str;
        description = "Upstream podcast RSS feed URL.";
        example = "https://feeds.acast.com/public/shows/fantasy-fangirls";
      };

      filter = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Case-insensitive substring to search for.

          When null, no text filtering is performed.
        '';
        example = "Everflame";
      };

      searchIn = mkOption {
        type = types.listOf (
          types.enum [
            "title"
            "body"
          ]
        );
        default = [ "title" ];
        description = ''
          Episode fields in which to look for `filter`.

          When multiple fields are listed, matching uses OR semantics:
          [ "title" "body" ] means the term may appear in either.
        '';
      };

      since = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional inclusive publication-date cutoff in YYYY-MM-DD format.

          This is combined with the text filter using AND semantics.
        '';
        example = "2025-05-05";
      };

      displayTitle = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Replacement podcast title for the generated feed.";
        example = "Fantasy Fangirls — Everflame";
      };

      caseSensitive = mkOption {
        type = types.bool;
        default = false;
        description = "Whether text matching is case-sensitive.";
      };
    };
  };

  feedConfig = pkgs.writeText "filtered-podcast-feeds.json" (builtins.toJSON cfg.feeds);
in
{
  options.genebean.services.filteredPodcastFeeds = {
    enable = mkEnableOption "filtered podcast RSS feeds";

    publicUrl = mkOption {
      type = types.str;
      description = ''
        Public base URL under which the host will serve `stateDir`'s
        contents (no trailing slash). Used only to rewrite each feed's Atom
        self-link; this module does not configure nginx itself.
      '';
      example = "https://podcasts.home.example.com/feeds";
    };

    refreshInterval = mkOption {
      type = types.str;
      default = "30m";
      description = "systemd time interval between feed refreshes.";
      example = "1h";
    };

    feeds = mkOption {
      type = types.attrsOf feedType;
      default = { };
      description = ''
        Filtered podcast feeds. Each attribute name becomes the generated
        feed slug, served from `${stateDir}/<slug>.xml`.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = lib.mapAttrsToList (name: feed: {
      assertion = feed.filter == null || feed.searchIn != [ ];
      message = ''
        genebean.services.filteredPodcastFeeds.feeds.${name}: searchIn must not be empty when filter is set.
      '';
    }) cfg.feeds;

    # Not DynamicUser: its state directory lands under /var/lib/private/<name>,
    # which is 0700 root:root - nginx (a different, static user) can never
    # traverse it to read the generated feeds, regardless of the leaf
    # directory's own mode. A fixed system user keeps /var/lib/<name> a real,
    # normally-permissioned directory. See modules/hosts/nixos/nixnuc/
    # social-reader-mcp.nix for the same tradeoff made previously.
    users.users.filtered-podcast-feeds = {
      isSystemUser = true;
      group = "filtered-podcast-feeds";
    };
    users.groups.filtered-podcast-feeds = { };

    systemd.services.filtered-podcast-feeds = {
      description = "Generate filtered podcast RSS feeds";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      environment = {
        FEED_CONFIG = feedConfig;
        OUTPUT_DIR = stateDir;
        PUBLIC_URL = cfg.publicUrl;
      };

      serviceConfig = {
        Type = "oneshot";
        User = "filtered-podcast-feeds";
        Group = "filtered-podcast-feeds";
        StateDirectory = "filtered-podcast-feeds";
        StateDirectoryMode = "0755";
        ExecStart = "${pkgs.filtered-podcast-feeds}/bin/filtered-podcast-feeds";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };

    systemd.timers.filtered-podcast-feeds = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = cfg.refreshInterval;
        RandomizedDelaySec = "60s";
        Unit = "filtered-podcast-feeds.service";
      };
    };
  };
}
