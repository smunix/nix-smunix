{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.chats.discord;
in {
  options.modules.desktop.chats.discord.enable =
    lib.mkEnableOption "Discord desktop chat client";

  config = lib.mkIf cfg.enable {
    hm.home.packages = [pkgs.discord];
  };
}
