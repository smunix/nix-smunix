{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.editors.zed;
in {
  options.modules.desktop.editors.zed.enable =
    lib.mkEnableOption "Zed editor";

  config = lib.mkIf cfg.enable {
    hm.programs.zed-editor = {
      enable = true;
      extensions = ["nix"];
      userSettings = {
        base_keymap = "VSCode";
        vim_mode = true;
        ui_font_size = 16.0 * config.modules.desktop.fonts.compact.factor;
        buffer_font_size = 16.0 * config.modules.desktop.fonts.compact.factor;
      };
    };
  };
}
