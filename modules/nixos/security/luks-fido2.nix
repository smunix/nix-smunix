{
  config,
  lib,
  ...
}: let
  cfg = config.modules.security.luksFido2;
in {
  options.modules.security.luksFido2 = {
    enable = lib.mkEnableOption "FIDO2 unlocking for LUKS2 devices in the systemd initrd";

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["cryptroot" "cryptswap"];
      description = "Names of boot.initrd.luks.devices entries already enrolled with systemd-cryptenroll.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.devices != [];
        message = "modules.security.luksFido2.devices must select at least one host-declared LUKS device.";
      }
    ];

    boot.initrd = {
      systemd = {
        enable = true;
        fido2.enable = true;
      };

      luks.devices = lib.genAttrs cfg.devices (_: {
        crypttabExtraOpts = lib.mkAfter ["fido2-device=auto"];
      });
    };
  };
}
