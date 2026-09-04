{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.shell.zellij;
in {
  options.modules.shell.zellij.enable =
    lib.mkEnableOption "Zellij terminal multiplexer";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.shell.default == "nushell";
        message = "Zellij is configured to use Nushell; set modules.shell.default to \"nushell\".";
      }
      {
        assertion = config.modules.desktop.editors.default == "helix";
        message = "Zellij is configured to use Helix; set modules.desktop.editors.default to \"helix\".";
      }
    ];

    hm.programs.zellij = {
      enable = true;
      settings = {
        default_shell = "${pkgs.nushell}/bin/nu";
        scrollback_editor = "${pkgs.helix}/bin/hx";
        copy_on_select = false;
        mouse_mode = true;
        pane_frames = true;
        show_startup_tips = false;
        show_release_notes = false;
      };
    };
  };
}
