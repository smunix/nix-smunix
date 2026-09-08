{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) genAttrs mkEnableOption mkForce mkIf mkMerge mkOption types;
  cfg = config.modules.security.fingerprint;
  overlap = lib.intersectLists cfg.pamServices cfg.disabledPamServices;
  validFingers = [
    "left-thumb"
    "left-index-finger"
    "left-middle-finger"
    "left-ring-finger"
    "left-little-finger"
    "right-thumb"
    "right-index-finger"
    "right-middle-finger"
    "right-ring-finger"
    "right-little-finger"
  ];
  configuredFingers = lib.escapeShellArgs cfg.enrollment.fingers;
  enrollmentTools = pkgs.writeShellApplication {
    name = "fingerprint-enroll-configured";
    runtimeInputs = [cfg.package];
    text = ''
      if (( $# == 0 )); then
        set -- ${configuredFingers}
      fi

      for finger in "$@"; do
        printf 'Enrolling %s for %s\n' "$finger" "$USER"
        fprintd-enroll -f "$finger"
      done

      fprintd-list "$USER"
    '';
  };
  verificationTools = pkgs.writeShellApplication {
    name = "fingerprint-verify-configured";
    runtimeInputs = [cfg.package];
    text = ''
      if (( $# == 0 )); then
        set -- ${configuredFingers}
      fi

      fprintd-list "$USER"
      for finger in "$@"; do
        printf 'Verifying %s for %s\n' "$finger" "$USER"
        fprintd-verify -f "$finger"
      done
    '';
  };
  listTool = pkgs.writeShellApplication {
    name = "fingerprint-list";
    runtimeInputs = [cfg.package];
    text = ''
      exec fprintd-list "$USER"
    '';
  };
in {
  options.modules.security.fingerprint = {
    enable = mkEnableOption "fingerprint authentication through fprintd with password fallback";

    package = mkOption {
      type = types.package;
      default = pkgs.fprintd;
      defaultText = lib.literalExpression "pkgs.fprintd";
      description = "fprintd package and PAM module used for fingerprint authentication.";
    };

    enrollment.fingers = mkOption {
      type = types.listOf (types.enum validFingers);
      default = [
        "left-index-finger"
        "right-index-finger"
      ];
      description = "Fingerprints enrolled and verified by the generated helper commands.";
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
      {
        assertion = cfg.enrollment.fingers != [];
        message = "At least one fingerprint must be selected for the enrollment helpers.";
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

    user.packages = [
      enrollmentTools
      verificationTools
      listTool
    ];
  };
}
