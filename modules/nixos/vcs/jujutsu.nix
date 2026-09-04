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
    assertions = [
      {
        assertion = config.user.description != "";
        message = "Jujutsu requires user.description to define the commit author name.";
      }
      {
        assertion = config.user.email != "";
        message = "Jujutsu requires user.email to define the commit author email.";
      }
    ];

    hm.programs.jujutsu = {
      enable = true;
      package = pkgs.jujutsu;
      settings = {
        ui.default-command = "log";
        user = {
          name = config.user.description;
          email = config.user.email;
        };
      };
    };
  };
}
