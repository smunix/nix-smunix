{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    rustPkgs = pkgs.extend inputs.rust-overlay.overlays.default;
    customPackages = import ../pkgs rustPkgs;
    projectPkgs = rustPkgs.extend (_final: _prev: customPackages);
    ayaVmPackages =
      if system == "x86_64-linux"
      then
        import ../pkgs/aya-vm-package.nix {
          pkgs = projectPkgs;
          inherit system;
          flakePath = ../.;
          nixpkgs = inputs.nixpkgs;
        }
      else null;
  in {
    packages =
      customPackages
      // inputs.nixpkgs.lib.optionalAttrs (ayaVmPackages != null) {
        aya-ebpf-vm = ayaVmPackages.vm;
        ebpf-vm = ayaVmPackages.runner;
      };

    formatter = pkgs.alejandra;
  };
}
