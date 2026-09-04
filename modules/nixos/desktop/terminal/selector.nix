{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.terminal;
in {
  options.modules.desktop.terminal.default = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum [
      "ghostty"
      "wezterm"
    ]);
    default = null;
    description = "Default terminal emulator for desktop applications.";
  };

  config = lib.mkIf (cfg.default != null) {
    environment.variables.TERMINAL = cfg.default;
    hm.home.sessionVariables.TERMINAL = cfg.default;
  };
}
