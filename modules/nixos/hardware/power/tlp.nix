{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.power.tlp;
in {
  options.modules.hardware.power.tlp = {
    enable = lib.mkEnableOption "TLP laptop power management";

    startChargeThreshold = lib.mkOption {
      type = lib.types.ints.between 0 100;
      default = 75;
      description = "Battery percentage below which charging BAT0 may start.";
    };

    stopChargeThreshold = lib.mkOption {
      type = lib.types.ints.between 0 100;
      default = 80;
      description = "Battery percentage at which charging BAT0 stops.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.startChargeThreshold < cfg.stopChargeThreshold;
        message = "TLP startChargeThreshold must be lower than stopChargeThreshold.";
      }
    ];

    services = {
      power-profiles-daemon.enable = false;
      tlp = {
        enable = true;
        pd.enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          START_CHARGE_THRESH_BAT0 = cfg.startChargeThreshold;
          STOP_CHARGE_THRESH_BAT0 = cfg.stopChargeThreshold;
          RUNTIME_PM_ON_BAT = "auto";
        };
      };
    };
  };
}
