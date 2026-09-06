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
        font_size = 13.0 * config.modules.desktop.fonts.compact.factor;
        default_prog = [
          "${pkgs.nushell}/bin/nu"
          "--login"
        ];
      };
    };
  };
}
