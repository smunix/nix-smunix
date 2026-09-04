{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.typst;
in {
  options.modules.develop.typst.enable =
    lib.mkEnableOption "Typst typesetting development tools";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [
      tinymist
      typst
      typstyle
    ];

    environment.shellAliases = {
      ts = "typst";
      tf = "typstyle";
    };
  };
}
