{lib, ...}: let
  attrs = import ../../lib/attrs.nix {inherit lib;};
  moduleLib = import ../../lib/modules.nix {
    inherit lib;
    inherit (attrs) mapFilterAttrs;
  };
in {
  imports = moduleLib.mapModulesRec' ./. import;
}
