{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.shell;
in {
  options.modules.shell.default = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum ["nushell"]);
    default = null;
    description = "Default login shell for the primary user.";
  };

  config = lib.mkIf (cfg.default == "nushell") {
    environment.shells = [pkgs.nushell];
    users.users.${config.user.name}.shell = pkgs.nushell;
    environment.variables.SHELL = "${pkgs.nushell}/bin/nu";

    hm = {
      home.sessionVariables.SHELL = "${pkgs.nushell}/bin/nu";

      programs.nushell = {
        enable = true;
        environmentVariables = {
          SHELL = "${pkgs.nushell}/bin/nu";
          EDITOR = "hx";
          VISUAL = "hx";
        };
        shellAliases = {
          l = "ls";
          ll = "ls -la";
          z = "zeditor";
          zed = "zeditor";
        };
      };
    };
  };
}
