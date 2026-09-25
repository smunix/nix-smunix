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

    deploy.nodes.vps-73025e99 = {
      hostname = "vps-73025e99.vps.ovh.ca";
      profiles.system = {
        user = "root";
        sshUser = "smunix";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.vps-73025e99;
      };
    };
  };
}
