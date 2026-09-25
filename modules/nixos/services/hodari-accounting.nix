{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.hodari-accounting;
  pkg = inputs.hodari-accounting.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.modules.services.hodari-accounting = {
    enable = lib.mkEnableOption "the Hodari Accounting & Invoicing web server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkg;
      description = "The Hodari Accounting server package.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Internal loopback port for the Hodari server.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Environment file containing runtime secrets (e.g. SURREALDB_USER, SURREALDB_PASS).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the internal port in the firewall (defaults to false when behind Caddy).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.hodari-accounting = {
      description = "Hodari Accounting Web Application (Dioxus + SurrealDB)";
      after = [
        "network.target"
        "sops-nix.service"
      ];
      wantedBy = ["multi-user.target"];

      environment = {
        HODARI_ASSETS_DIR = "${cfg.package}/share/hodari/assets";
      };

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/hodari-server";
        Restart = "always";
        RestartSec = "5s";
        DynamicUser = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}
