# Custom packages exported through the additions overlay and per-system outputs.
pkgs: let
  ayaToolchain = pkgs.rust-bin.nightly."2026-07-15".minimal;
  ayaRustPlatform = pkgs.makeRustPlatform {
    cargo = ayaToolchain;
    rustc = ayaToolchain;
  };
in {
  aya-tool = pkgs.callPackage ./aya-tool.nix {
    rustPlatform = ayaRustPlatform;
  };
  bpf-linker-aya = pkgs.callPackage ./bpf-linker.nix {};
}
