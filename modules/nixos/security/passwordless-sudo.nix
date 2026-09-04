{
  config,
  lib,
  ...
}: let
  cfg = config.modules.security.passwordlessSudo;
in {
  options.modules.security.passwordlessSudo.enable =
    lib.mkEnableOption "passwordless sudo for the primary user";

  config = lib.mkIf cfg.enable {
    security.sudo.extraRules = [
      {
        users = [config.user.name];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
