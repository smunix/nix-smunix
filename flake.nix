{
  description = "Modular NixOS and Home Manager configuration for smunix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    secrets = {
      url = "git+ssh://git@github.com/smunix/nix-secrets?shallow=1";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

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

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }: let
    projectLib = import ./lib {
      inherit inputs;
      inherit (nixpkgs) lib;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.home-manager.flakeModules.home-manager
        ./parts/flake.nix
        ./parts/per-system.nix
      ];

      _module.args = {inherit projectLib;};

      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
}
