{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.rust;
in {
  options.modules.develop.rust.enable =
    lib.mkEnableOption "Rust development tools";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [
      cargo
      clippy
      rust-analyzer
      rustc
      rustfmt
    ];

    environment.shellAliases = {
      ca = "cargo";
      rs = "rustc";
    };
  };
}
