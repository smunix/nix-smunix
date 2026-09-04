{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.editors;
  commands = {
    helix = "hx";
    vim = "vim";
    zed = "zeditor";
  };
in {
  options.modules.desktop.editors.default = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum [
      "helix"
      "vim"
      "zed"
    ]);
    default = null;
    description = "Default text editor for command-line tools.";
  };

  config = lib.mkIf (cfg.default != null) {
    environment.variables = {
      EDITOR = commands.${cfg.default};
      VISUAL = commands.${cfg.default};
    };
  };
}
