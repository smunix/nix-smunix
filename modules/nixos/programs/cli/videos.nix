{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.programs.cli.videos;
in {
  options.modules.programs.cli.videos.enable =
    lib.mkEnableOption "command-line videos and discovery utilities";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [
      ffmpeg
      yt-dlp
    ];
  };
}
