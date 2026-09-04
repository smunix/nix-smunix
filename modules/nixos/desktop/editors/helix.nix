{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.editors.helix;
in {
  options.modules.desktop.editors.helix.enable =
    lib.mkEnableOption "Helix editor";

  config = lib.mkIf cfg.enable {
    hm.programs.helix = {
      enable = true;
      defaultEditor = config.modules.desktop.editors.default == "helix";
      settings.editor = {
        auto-format = true;
        line-number = "relative";
        mouse = true;
      };
    };
  };
}
