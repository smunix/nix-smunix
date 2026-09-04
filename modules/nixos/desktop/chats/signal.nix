{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.chats.signal;
in {
  options.modules.desktop.chats.signal.enable =
    lib.mkEnableOption "Signal Desktop chat client";

  config = lib.mkIf cfg.enable {
    hm.home.packages = [pkgs.signal-desktop];
  };
}
