{
  config,
  lib,
  ...
}: let
  cfg = config.modules.base;
in {
  options.modules.base.enable =
    lib.mkEnableOption "the base Home Manager profile";

  config = lib.mkIf cfg.enable {
    programs.home-manager.enable = true;
  };
}
