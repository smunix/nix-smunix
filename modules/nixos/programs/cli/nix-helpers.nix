{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.programs.cli.nix-helpers;
in {
  options.modules.programs.cli.nix-helpers = {
    enable = lib.mkEnableOption "Nix productivity CLI helpers such as nh and nom";

    flake = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "${config.user.home}/Projects/nix/nix-config";
      description = "Default flake path used by nh (sets the NH_FLAKE environment variable).";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      flake = cfg.flake;
    };

    user.packages = with pkgs; [
      nix-output-monitor
      nvd
    ];
  };
}
