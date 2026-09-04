{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.printing;
in {
  options.modules.hardware.printing.enable =
    lib.mkEnableOption "CUPS printing support";

  config = lib.mkIf cfg.enable {
    services.printing.enable = true;
  };
}
