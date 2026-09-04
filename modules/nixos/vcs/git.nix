{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.vcs.git;
in {
  options.modules.vcs.git.enable =
    lib.mkEnableOption "Git version control";

  config = lib.mkIf cfg.enable {
    programs.ssh.askPassword = "";

    hm.programs.git = {
      enable = true;
      package = pkgs.gitFull;
      settings = {
        alias = {
          co = "checkout";
          st = "status";
          unadd = "reset HEAD";
        };
        init.defaultBranch = "main";
      };
    };
  };
}
