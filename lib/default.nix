{
  inputs,
  lib,
}: let
  attrs = import ./attrs.nix {inherit lib;};

  modules = import ./modules.nix {
    inherit lib;
    inherit (attrs) mapFilterAttrs;
  };

  nixos = import ./nixos.nix {
    inherit inputs lib;
    inherit (modules) mapModules;
  };
in
  attrs // modules // nixos
