{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.viewers.tdf;
in {
  options.modules.desktop.viewers.tdf.enable =
    lib.mkEnableOption "TDF terminal PDF viewer";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [ poppler-utils tdf ];
  };
}
