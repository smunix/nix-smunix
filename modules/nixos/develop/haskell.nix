{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.haskell;
in {
  options.modules.develop.haskell.enable =
    lib.mkEnableOption "Haskell development tools";

  config = lib.mkIf cfg.enable {
    user.packages = with pkgs; [
      cabal-install
      ghc
      haskell-language-server
      hlint
    ];
  };
}
