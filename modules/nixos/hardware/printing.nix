{
  config,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkEnableOption mkIf mkOption types;
  cfg = config.modules.hardware.printing;
in {
  options.modules.hardware.printing = {
    enable = mkEnableOption "CUPS printing support";

    drivers = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExpression "with pkgs; [gutenprint hplip]";
      description = ''
        Additional CUPS printer drivers. Leave this empty for printers that
        support driverless IPP Everywhere or AirPrint.
      '';
    };

    networkDiscovery = {
      enable = mkEnableOption "network printer discovery through Avahi and DNS-SD";

      autoCreateQueues = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether cups-browsed should create local queues for compatible
          printers announced on the network.
        '';
      };

      resolveLocalNames = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether applications should resolve IPv4 .local host names through
          the Avahi NSS module.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to permit mDNS discovery traffic on UDP port 5353. This does
          not expose the local CUPS administration service to the network.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = cfg.drivers;
      browsed.enable =
        cfg.networkDiscovery.enable
        && cfg.networkDiscovery.autoCreateQueues;
    };

    services.avahi = mkIf cfg.networkDiscovery.enable {
      enable = true;
      nssmdns4 = cfg.networkDiscovery.resolveLocalNames;
      openFirewall = cfg.networkDiscovery.openFirewall;
    };
  };
}
