{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkAfter;
  cfg = config.modules.programs.obs;
in {
  options.modules.programs.obs = {
    enable = mkEnableOption "OBS Studio for recording and live streaming";

    ndi.enable = mkEnableOption "NDI network audio and video support through the obs-ndi compatibility package";

    virtualCamera.enable = mkEnableOption "the OBS virtual camera backed by v4l2loopback";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.ndi.enable || (pkgs.config.allowUnfree or false);
        message = "modules.programs.obs.ndi requires an unfree-enabled package set for the proprietary NDI SDK.";
      }
    ];

    programs.obs-studio = {
      enable = true;
      plugins = optional cfg.ndi.enable pkgs.obs-studio-plugins.obs-ndi;
      enableVirtualCamera = cfg.virtualCamera.enable;
    };

    user.extraGroups = mkAfter [
      "video"
      "render"
    ];
  };
}
