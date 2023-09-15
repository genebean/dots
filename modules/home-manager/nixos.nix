{ pkgs, ... }: {
  programs = {
    waybar = {
      enable = true;
    };
  };
  services.dunst = {
    enable = true;
    settings = {
      global = {
        frame_color = "#8CAAEE";
        separator_color= "frame";
      };

      urgency_low = {
        background = "#303446";
        foreground = "#C6D0F5";
      };

      urgency_normal = {
        background = "#303446";
        foreground = "#C6D0F5";
      };

      urgency_critical = {
        background = "#303446";
        foreground = "#C6D0F5";
        frame_color = "#EF9F76";
      };
    };
  };
}

