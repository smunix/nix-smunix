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
        user = {
          name = config.user.description;
          email = config.user.email;
        };
        url."git@github.com-dama:".insteadOf = [
          "git@github.com:damaconstruction/"
          "https://github.com/damaconstruction/"
        ];
      };
      includes = [
        {
          condition = "gitdir:~/Projects/dama/";
          contents = {
            user = {
              name = config.user.description;
              email = "psalumu@damaconstruction.com";
            };
            core = {
              sshCommand = "ssh -i ~/.ssh/id_ed25519_dama -o IdentitiesOnly=yes";
            };
          };
        }
        {
          condition = "gitdir:~/Projects/work/";
          contents = {
            user = {
              name = config.user.description;
              email = "psalumu@damaconstruction.com";
            };
            core = {
              sshCommand = "ssh -i ~/.ssh/id_ed25519_dama -o IdentitiesOnly=yes";
            };
          };
        }
      ];
    };
  };
}
