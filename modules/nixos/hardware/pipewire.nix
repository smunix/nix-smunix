{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.pipewire;
in {
  options.modules.hardware.pipewire.enable =
    lib.mkEnableOption "PipeWire audio support";

  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };
}
