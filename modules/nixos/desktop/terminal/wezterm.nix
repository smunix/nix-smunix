{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.terminal;
in {
  options.modules.desktop.terminal.default = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum ["wezterm"]);
    default = null;
    description = "Default terminal emulator for the desktop session.";
  };

  config = lib.mkIf (cfg.default == "wezterm") {
    environment.variables.TERMINAL = "wezterm";

    hm = {
      home.sessionVariables.TERMINAL = "wezterm";
      programs.wezterm = {
        enable = true;
        settings.default_prog = [
          "${pkgs.nushell}/bin/nu"
          "--login"
        ];
      };
    };
  };
}
