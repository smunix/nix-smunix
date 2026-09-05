{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.programs.cli.search;
in {
  options.modules.programs.cli.search.enable =
    lib.mkEnableOption "command-line search and discovery utilities";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [
      ack
      fd
      ripgrep
    ];
  };
}
