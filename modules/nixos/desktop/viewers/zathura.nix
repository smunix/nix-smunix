{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.viewers.zathura;
in {
  options.modules.desktop.viewers.zathura.enable =
    lib.mkEnableOption "Zathura document viewer";

  config = lib.mkIf cfg.enable {
    user.packages = [pkgs.zathura];
  };
}
