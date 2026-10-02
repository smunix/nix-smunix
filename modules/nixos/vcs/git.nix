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
        url."git@github.com-dama:damabloom/".insteadOf = [
          "git@github.com:damabloom/"
          "https://github.com/damabloom/"
        ];
        url."git@github.com-dama:psalumu-dama/".insteadOf = [
          "git@github.com:psalumu-dama/"
          "https://github.com/psalumu-dama/"
        ];
        url."git@gitlab.com-dama:damacs1/".insteadOf = [
          "git@gitlab.com:damacs1/"
          "https://gitlab.com/damacs1/"
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
            url."git@github.com-dama:".insteadOf = [
              "git@github.com:"
              "https://github.com/"
            ];
            url."git@gitlab.com-dama:".insteadOf = [
              "git@gitlab.com:"
              "https://gitlab.com/"
            ];
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
            url."git@github.com-dama:".insteadOf = [
              "git@github.com:"
              "https://github.com/"
            ];
            url."git@gitlab.com-dama:".insteadOf = [
              "git@gitlab.com:"
              "https://gitlab.com/"
            ];
          };
        }
      ];
    };
  };
}
