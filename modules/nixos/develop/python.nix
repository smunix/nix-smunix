{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.python;
in {
  options.modules.develop.python.enable =
    lib.mkEnableOption "Python development tools";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [
      pyright
      python3
      ruff
      uv
    ];

    environment.shellAliases.py = "python3";
  };
}
