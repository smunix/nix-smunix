{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.editors.vim;
in {
  options.modules.desktop.editors.vim.enable =
    lib.mkEnableOption "Vim editor";

  config = lib.mkIf cfg.enable {
    hm.programs.vim = {
      enable = true;
      defaultEditor = config.modules.desktop.editors.default == "vim";
      settings = {
        expandtab = true;
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
      };
    };
  };
}
