{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.niri;
in {
  options.modules.desktop.niri.enable =
    lib.mkEnableOption "the Niri Wayland compositor";

  config = lib.mkIf cfg.enable {
    programs.niri.enable = true;
  };
}
