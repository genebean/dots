{ config, ... }:
let
  home_domain = "home.technicalissues.us";
in
{
  genebean.services.filteredPodcastFeeds = {
    enable = true;

    publicUrl = "https://podcasts.${home_domain}/feeds";

    feeds.fantasy-fangirls-everflame = {
      source = "https://feeds.acast.com/public/shows/681a593c1d28d623131601be";
      filter = "Everflame";
      searchIn = [ "title" ];
      displayTitle = "Fantasy Fangirls — Everflame";
    };
  };

  sops.secrets.filtered_podcast_feeds_basic_auth = {
    sopsFile = ../../../shared/secrets.yaml;
    owner = config.users.users.nginx.name;
    restartUnits = [ "nginx.service" ];
  };
}
