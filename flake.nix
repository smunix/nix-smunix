{
  description = "Modular NixOS and Home Manager configuration for smunix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae.url = "github:vicinaehq/vicinae";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = inputs @ {nixpkgs, ...}: let
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    lib = nixpkgs.lib.extend (_final: _prev: {
      my = import ./lib {
        inherit inputs;
        inherit (nixpkgs) lib;
      };
    });
  in {
    lib = lib.my;

    packages = forAllSystems (
      system: import ./pkgs nixpkgs.legacyPackages.${system}
    );

    formatter = forAllSystems (
      system: nixpkgs.legacyPackages.${system}.alejandra
    );

    overlays = lib.my.mapModules ./overlays (
      path: import path {inherit inputs;}
    );

    nixosModules =
      {
        default = import ./.;
      }
      // lib.my.mapModulesRec ./modules/nixos import;

    homeManagerModules =
      {
        default = import ./modules/home-manager;
      }
      // lib.my.mapModulesRec ./modules/home-manager import;

    nixosConfigurations = lib.my.mapHosts ./hosts {};
  };
}
