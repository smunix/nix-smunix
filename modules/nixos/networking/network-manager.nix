{
  config,
  lib,
  ...
}: let
  cfg = config.modules.networking.networkManager;
in {
  options.modules.networking.networkManager.enable =
    lib.mkEnableOption "NetworkManager-based networking";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}
