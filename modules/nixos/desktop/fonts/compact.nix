{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.fonts.compact;
  factors = {
    "5" = 0.95;
    "10" = 0.9;
    "15" = 0.85;
    "20" = 0.8;
    "25" = 0.75;
    "30" = 0.7;
    "35" = 0.65;
  };
  factor =
    if cfg.enable
    then factors.${toString cfg.reduction}
    else 1.0;
  fixedSize = 10.0 * factor;
  generalSize = 11.0 * factor;
in {
  options.modules.desktop.fonts.compact = {
    enable = lib.mkEnableOption "a configurable reduction in desktop font sizes";

    reduction = lib.mkOption {
      type = lib.types.enum [5 10 15 20 25 30 35];
      default = 15;
      example = 20;
      description = "Percentage by which configured desktop and application font baselines are reduced.";
    };

    factor = lib.mkOption {
      type = lib.types.float;
      internal = true;
      readOnly = true;
      default = factor;
      description = "Effective multiplier derived from the selected reduction percentage.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."xdg/kdeglobals".text = ''
      [General]
      fixed=Maple Mono NF CN,${toString fixedSize},-1,5,400,0,0,0,0,0
      font=Noto Sans,${toString generalSize},-1,5,400,0,0,0,0,0
      menuFont=Noto Sans,${toString generalSize},-1,5,400,0,0,0,0,0
      smallestReadableFont=Noto Sans,${toString fixedSize},-1,5,400,0,0,0,0,0
      toolBarFont=Noto Sans,${toString generalSize},-1,5,400,0,0,0,0,0

      [WM]
      activeFont=Noto Sans,${toString generalSize},-1,5,500,0,0,0,0,0
    '';

    hm = {
      gtk.font = {
        name = "Noto Sans";
        package = pkgs.noto-fonts;
        size = generalSize;
      };

      xresources.properties."Xft.dpi" = 96.0 * factor;
    };
  };
}
