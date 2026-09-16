# Custom packages exported through the additions overlay and per-system outputs.
pkgs: {
  bpf-linker-aya = pkgs.callPackage ./bpf-linker.nix {};
}
