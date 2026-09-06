{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.terminal;
  enabled = cfg.ghostty.enable || cfg.default == "ghostty";
in {
  options.modules.desktop.terminal.ghostty.enable =
    lib.mkEnableOption "Ghostty terminal emulator";

  config = lib.mkIf enabled {
    hm.programs.ghostty = {
      enable = true;
      enableBashIntegration = false;
      installBatSyntax = false;
      settings = {
        theme = "smunix-noctalia";
        font-family = "Maple Mono NF CN";
        font-size = 13.0 * config.modules.desktop.fonts.compact.factor;
        window-decoration = false;
        background-opacity = 0.93;
        copy-on-select = "clipboard";
        scrollback-limit = 20000;
        command = "${pkgs.bash}/bin/bash --login -c '${pkgs.nushell}/bin/nu --login --interactive'";
      };
      themes.smunix-noctalia = {
        background = "24283b";
        foreground = "c0caf5";
        cursor-color = "c0caf5";
        selection-background = "364a82";
        selection-foreground = "c0caf5";
        palette = [
          "0=#15161e"
          "1=#f7768e"
          "2=#9ece6a"
          "3=#e0af68"
          "4=#7aa2f7"
          "5=#bb9af7"
          "6=#7dcfff"
          "7=#a9b1d6"
          "8=#414868"
          "9=#f7768e"
          "10=#9ece6a"
          "11=#e0af68"
          "12=#7aa2f7"
          "13=#bb9af7"
          "14=#7dcfff"
          "15=#c0caf5"
        ];
      };
    };
  };
}
