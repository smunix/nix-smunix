{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.power.lid;
  actionType = lib.types.enum [
    "ignore"
    "poweroff"
    "reboot"
    "halt"
    "kexec"
    "suspend"
    "hibernate"
    "hybrid-sleep"
    "suspend-then-hibernate"
    "lock"
  ];
in {
  options.modules.hardware.power.lid = {
    enable = lib.mkEnableOption "systemd-logind lid-switch actions";

    onBattery = lib.mkOption {
      type = actionType;
      default = "suspend";
      description = "Action taken when the lid closes while running on battery.";
    };

    onExternalPower = lib.mkOption {
      type = actionType;
      default = "suspend";
      description = "Action taken when the lid closes while using external power.";
    };

    whenDocked = lib.mkOption {
      type = actionType;
      default = "ignore";
      description = "Action taken when the lid closes while the computer is docked.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.logind.settings.Login = {
      HandleLidSwitch = cfg.onBattery;
      HandleLidSwitchExternalPower = cfg.onExternalPower;
      HandleLidSwitchDocked = cfg.whenDocked;
    };
  };
}
