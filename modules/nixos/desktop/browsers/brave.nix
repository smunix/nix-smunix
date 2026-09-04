{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.browsers.brave;
in {
  options.modules.desktop.browsers.brave.enable =
    lib.mkEnableOption "Brave browser";

  config = lib.mkIf cfg.enable {
    hm.programs.chromium = {
      enable = true;
      package = pkgs.brave;
    };
  };
}
