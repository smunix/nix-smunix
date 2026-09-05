{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.programs.cli.system;
in {
  options.modules.programs.cli.system.enable =
    lib.mkEnableOption "foundational command-line system utilities";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [
      coreutils
      pciutils
    ];
  };
}
