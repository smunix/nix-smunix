{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.security.yubikey;
  centralAuthFile = "/etc/security/u2f_mappings";
in {
  options.modules.security.yubikey = {
    enable = lib.mkEnableOption "passwordless YubiKey U2F authentication with password fallback";

    mappingFile = lib.mkOption {
      type = lib.types.path;
      default = inputs.secrets + "/hosts/${config.networking.hostName}/security/u2f_keys";
      description = "Central PAM U2F mapping supplied by the private secrets input.";
    };

    origin = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "pam://nixos";
      description = "Relying-party origin used when the U2F credential was enrolled.";
    };

    appId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "pam://nixos";
      description = "Application ID used when the U2F credential was enrolled.";
    };

    lockOnRemoval = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Lock all active sessions when a Yubico USB device is removed.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.pathExists cfg.mappingFile;
        message = "The configured YubiKey mapping file does not exist: ${toString cfg.mappingFile}";
      }
    ];

    environment.etc."security/u2f_mappings" = {
      source = cfg.mappingFile;
      mode = "0600";
      user = "root";
      group = "root";
    };

    programs.yubikey-manager.enable = true;

    security.pam.u2f = {
      enable = true;
      control = "sufficient";
      settings =
        {
          authfile = centralAuthFile;
          cue = true;
          userpresence = 1;
        }
        // lib.optionalAttrs (cfg.origin != null) {inherit (cfg) origin;}
        // lib.optionalAttrs (cfg.appId != null) {appid = cfg.appId;};
    };

    services.udev.extraRules = lib.optionalString cfg.lockOnRemoval ''
      ACTION=="remove", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="1050", RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
  };
}
