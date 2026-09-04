{
  config,
  lib,
  ...
}: let
  cfg = config.modules.shell.starship;
in {
  options.modules.shell.starship.enable =
    lib.mkEnableOption "Starship cross-shell prompt";

  config = lib.mkIf cfg.enable {
    hm.programs.starship = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
      settings = {
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
        aws.disabled = true;
        gcloud.disabled = true;
        kubernetes = {
          symbol = "⛵";
          disabled = false;
        };
        os.disabled = false;
      };
    };
  };
}
