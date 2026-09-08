{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) genAttrs mkEnableOption mkForce mkIf mkMerge mkOption types;
  cfg = config.modules.security.fingerprint;
  overlap = lib.intersectLists cfg.pamServices cfg.disabledPamServices;
in {
  options.modules.security.fingerprint = {
    enable = mkEnableOption "fingerprint authentication through fprintd with password fallback";

    package = mkOption {
      type = types.package;
      default = pkgs.fprintd;
      defaultText = lib.literalExpression "pkgs.fprintd";
      description = "fprintd package and PAM module used for fingerprint authentication.";
    };

    pamServices = mkOption {
      type = types.listOf types.str;
      default = [
        "i3lock"
        "i3lock-color"
        "kde-fingerprint"
        "login"
        "polkit-1"
        "sddm"
        "su"
        "sudo"
        "swaylock"
        "systemd-run0"
        "vlock"
        "xlock"
        "xscreensaver"
      ];
      description = "Interactive PAM services that accept an enrolled fingerprint.";
    };

    disabledPamServices = mkOption {
      type = types.listOf types.str;
      default = [
        "chfn"
        "chpasswd"
        "chsh"
        "cups"
        "groupadd"
        "groupdel"
        "groupmems"
        "groupmod"
        "kde"
        "other"
        "passwd"
        "runuser"
        "runuser-l"
        "sddm-autologin"
        "sddm-greeter"
        "systemd-user"
        "useradd"
        "userdel"
        "usermod"
      ];
      description = "Noninteractive or account-mutating PAM services that must not accept fingerprints.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = overlap == [];
        message = "Fingerprint PAM services cannot be both enabled and disabled: ${lib.concatStringsSep ", " overlap}";
      }
    ];

    services.fprintd = {
      enable = true;
      package = cfg.package;
    };

    security.pam.services = mkMerge [
      (genAttrs cfg.pamServices (_: {fprintAuth = true;}))
      (genAttrs cfg.disabledPamServices (_: {fprintAuth = mkForce false;}))
    ];
  };
}
