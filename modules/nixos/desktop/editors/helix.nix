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
        cursorline = true;
        mouse = true;
        gutters = ["diff" "diagnostics" "line-numbers" "spacer"];
        text-width = 100;
        rulers = [100];
        lsp = {
          auto-signature-help = true;
          display-inlay-hints = true;
        };
      };
      languages = {
        language-server.rust-analyzer.config = {
          check = {
            command = "clippy";
          };
          cargo = {
            allFeatures = true;
          };
          procMacro = {
            enable = true;
          };
        };
      };
    };
  };
}
