{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.quarto;
in {
  options.modules.develop.quarto.enable =
    lib.mkEnableOption "Quarto scientific and technical publishing tools";

  config = lib.mkIf cfg.enable {
    user.packages = [pkgs.quarto];

    environment.shellAliases = {
      qr = "quarto render";
      qp = "quarto preview";
    };
  };
}
