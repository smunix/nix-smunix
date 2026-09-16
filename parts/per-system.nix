{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    customPackages = import ../pkgs pkgs;
    ayaVmPackages =
      if system == "x86_64-linux"
      then
        import ../pkgs/aya-vm-package.nix {
          inherit pkgs system;
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
