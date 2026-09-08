{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.plasma;
in {
  options.modules.desktop.plasma = {
    enable = lib.mkEnableOption "the KDE Plasma 6 desktop";

    screenLock = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether Plasma automatically locks the session after inactivity.";
      };

      timeoutMinutes = lib.mkOption {
        type = lib.types.numbers.positive;
        default = 10;
        description = "Minutes of inactivity before Plasma locks the session.";
      };

      lockOnResume = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether Plasma requires authentication after resuming from suspend.";
      };

      graceSeconds = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 0;
        description = "Seconds after locking during which Plasma permits unlock without authentication.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
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
    }
    (lib.mkIf cfg.screenLock.enable {
      hm.xdg.configFile."kscreenlockerrc".text = lib.generators.toINI {} {
        Daemon = {
          Autolock = true;
          Timeout = cfg.screenLock.timeoutMinutes;
          Lock = true;
          LockGrace = cfg.screenLock.graceSeconds;
          RequirePassword = true;
          LockOnResume = cfg.screenLock.lockOnResume;
        };
      };
    })
  ]);
}
