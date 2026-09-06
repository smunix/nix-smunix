{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.ai;
  clients = {
    kimi = pkgs.kimi-code;
  };
in {
  options.modules.ai = {
    enable = lib.mkEnableOption "an AI coding client";

    client = lib.mkOption {
      type = lib.types.enum ["kimi"];
      default = "kimi";
      example = "kimi";
      description = "AI coding client to install. Additional clients can be added to the selector later.";
    };
  };

  config = lib.mkIf cfg.enable {
    user.packages = [clients.${cfg.client}];
  };
}
