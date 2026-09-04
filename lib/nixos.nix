{
  inputs,
  lib,
  mapModules,
}: let
  inherit (builtins) attrValues baseNameOf elem;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.modules) mkDefault;
  inherit (lib.strings) removeSuffix;
in rec {
  mkHost = path: attrs @ {system ? "x86_64-linux", ...}: let
    hostName = removeSuffix ".nix" (baseNameOf path);
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = attrValues inputs.self.overlays;
    };
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs lib system;
      };

      modules = [
        {
          networking.hostName = mkDefault hostName;
          nixpkgs.pkgs = pkgs;
        }
        (filterAttrs (name: _value: !(elem name ["system"])) attrs)
        ../.
        (import path)
      ];
    };

  mapHosts = dir: attrs:
    mapModules dir (hostPath: mkHost hostPath attrs);
}
