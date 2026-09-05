{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.power;
in {
  options.modules.hardware.power.backend = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum [
      "upower"
      "tlp"
    ]);
    default = null;
    description = ''
      Selects the laptop power-policy backend. TLP mode keeps UPower enabled
      as a battery telemetry and desktop-integration companion.
    '';
  };

  config = lib.mkIf (cfg.backend != null) {
    modules.hardware.power = {
      tlp.enable = lib.mkDefault (cfg.backend == "tlp");
      upower.enable = lib.mkDefault true;
    };
  };
}
