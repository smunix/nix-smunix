{
  inputs,
  projectLib,
  ...
}: let
  homeModules =
    {
      default = import ../modules/home-manager;
    }
    // projectLib.mapModulesRec ../modules/home-manager import;
in {
  flake = {
    lib = projectLib;

    overlays = projectLib.mapModules ../overlays (
      path: import path {inherit inputs;}
    );

    nixosModules =
      {
        default = import ../.;
      }
      // projectLib.mapModulesRec ../modules/nixos import;

    inherit homeModules;
    homeManagerModules = homeModules;

    nixosConfigurations = projectLib.mapHosts ../hosts {};
  };
}
