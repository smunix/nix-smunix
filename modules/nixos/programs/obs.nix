{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption types;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkAfter;
  cfg = config.modules.programs.obs;
in {
  options.modules.programs.obs = {
    enable = mkEnableOption "OBS Studio for recording and live streaming";
    ndi.enable = mkEnableOption "NDI network audio and video support through the obs-ndi compatibility package";

    virtualCamera = {
      enable = mkEnableOption "the OBS virtual camera backed by v4l2loopback";
      videoNr = mkOption {
        type = types.ints.between 0 255;
        default = 10;
        description = "Video device number assigned to the OBS virtual camera.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.ndi.enable || (pkgs.config.allowUnfree or false);
          message = "modules.programs.obs.ndi requires an unfree-enabled package set for the proprietary NDI SDK.";
        }
      ];

      programs.obs-studio = {
        enable = true;
        plugins = optional cfg.ndi.enable pkgs.obs-studio-plugins.obs-ndi;
      };

      user.extraGroups = mkAfter [
        "video"
        "render"
      ];
    }

    (mkIf cfg.virtualCamera.enable {
      boot = {
        kernelModules = ["v4l2loopback"];
        extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
        extraModprobeConfig = ''
          options v4l2loopback devices=1 video_nr=${toString cfg.virtualCamera.videoNr} card_label="OBS Cam" exclusive_caps=1
        '';
      };
      security.polkit.enable = true;
    })
  ]);
}
