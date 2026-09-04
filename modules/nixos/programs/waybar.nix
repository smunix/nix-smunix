{
  config,
  lib,
  ...
}: let
  cfg = config.modules.programs.waybar;
in {
  options.modules.programs.waybar.enable =
    lib.mkEnableOption "Waybar";

  config = lib.mkIf cfg.enable {
    programs.waybar.enable = true;
  };
}
