{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.terminal;
  enabled = cfg.wezterm.enable || cfg.default == "wezterm";
in {
  options.modules.desktop.terminal.wezterm.enable =
    lib.mkEnableOption "WezTerm terminal emulator";

  config = lib.mkIf enabled {
    hm.programs.wezterm = {
      enable = true;
      settings = {
        font_size = 11.05;
        default_prog = [
          "${pkgs.nushell}/bin/nu"
          "--login"
        ];
      };
    };
  };
}
