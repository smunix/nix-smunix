{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.fonts.compact;
in {
  options.modules.desktop.fonts.compact.enable =
    lib.mkEnableOption "a 15 percent reduction in desktop font sizes";

  config = lib.mkIf cfg.enable {
    environment.etc."xdg/kdeglobals".text = ''
      [General]
      fixed=Maple Mono NF CN,8.5,-1,5,400,0,0,0,0,0
      font=Noto Sans,9.35,-1,5,400,0,0,0,0,0
      menuFont=Noto Sans,9.35,-1,5,400,0,0,0,0,0
      smallestReadableFont=Noto Sans,8.5,-1,5,400,0,0,0,0,0
      toolBarFont=Noto Sans,9.35,-1,5,400,0,0,0,0,0

      [WM]
      activeFont=Noto Sans,9.35,-1,5,500,0,0,0,0,0
    '';

    hm = {
      gtk.font = {
        name = "Noto Sans";
        package = pkgs.noto-fonts;
        size = 9.35;
      };

      xresources.properties."Xft.dpi" = 81.6;
    };
  };
}
