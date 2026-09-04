{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.vcs.jujutsu;
in {
  options.modules.vcs.jujutsu.enable =
    lib.mkEnableOption "Jujutsu version control";

  config = lib.mkIf cfg.enable {
    hm.programs.jujutsu = {
      enable = true;
      package = pkgs.jujutsu;
      settings.ui.default-command = "log";
    };
  };
}
