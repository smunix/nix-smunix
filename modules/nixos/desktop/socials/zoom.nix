{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.socials.zoom;
in {
  imports = [
    (lib.mkAliasOptionModule ["modules" "socials"] ["modules" "desktop" "socials"])
  ];

  options.modules.desktop.socials.zoom = {
    enable = lib.mkEnableOption "Zoom video conferencing application";
  };

  config = lib.mkIf cfg.enable {
    hm.home.packages = [pkgs.zoom-us];
  };
}
