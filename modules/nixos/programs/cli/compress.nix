{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.programs.cli.compress;
in {
  options.modules.programs.cli.compress.enable =
    lib.mkEnableOption "command-line compress and discovery utilities";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [
      dtrx
      unzip
    ];
  };
}

