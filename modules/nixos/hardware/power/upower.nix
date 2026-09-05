{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.power.upower;
in {
  options.modules.hardware.power.upower.enable =
    lib.mkEnableOption "UPower battery telemetry and desktop integration";

  config = lib.mkIf cfg.enable {
    services.upower = {
      enable = true;
      usePercentageForPolicy = true;
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 2;
      criticalPowerAction = "HybridSleep";
    };
  };
}
