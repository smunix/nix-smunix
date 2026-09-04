{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.plasma;
in {
  options.modules.desktop.plasma.enable =
    lib.mkEnableOption "the KDE Plasma 6 desktop";

  config = lib.mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };
      };

      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;
    };
  };
}
