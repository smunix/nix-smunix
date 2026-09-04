{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.packages;
in {
  options.modules.packages.enable =
    lib.mkEnableOption "the default user package set";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      evince
      helix
      home-manager
      jujutsu
    ];
  };
}
