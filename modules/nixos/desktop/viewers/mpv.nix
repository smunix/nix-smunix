{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.viewers.mpv;
in {
  options.modules.desktop.viewers.mpv.enable =
    lib.mkEnableOption "MPV media viewer";

  config = lib.mkIf cfg.enable {
    user.packages = [pkgs.mpv];
  };
}
