{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.cc;
in {
  options.modules.develop.cc.enable =
    lib.mkEnableOption "C and C++ development tools";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [
      clang
      clang-tools
      cmake
      gcc
      gdb
      gnumake
      pkg-config
    ];
  };
}
