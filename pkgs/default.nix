# Custom packages exported through the additions overlay and per-system outputs.
pkgs: let
  rustPolicy = import ./rust-toolchain-policy.nix;
  rustBuildToolchain = pkgs.rust-bin.${rustPolicy.channel}.${rustPolicy.version}.minimal;
  rustDeveloperToolchain = pkgs.rust-bin.${rustPolicy.channel}.${rustPolicy.version}.default.override {
    extensions = [
      "rust-src"
      "rustfmt"
      "clippy"
      "rust-analyzer"
    ];
  };
  rustPlatform = pkgs.makeRustPlatform {
    cargo = rustBuildToolchain;
    rustc = rustBuildToolchain;
  };
  wasmBindgenCli = pkgs.callPackage ./wasm-bindgen-cli-0_2_128.nix {
    inherit rustPlatform;
  };
in
  {
    rust-toolchain-smunix = rustDeveloperToolchain;
    aya-tool = pkgs.callPackage ./aya-tool.nix {
      inherit rustPlatform;
    };
    bpf-linker-aya = pkgs.callPackage ./bpf-linker.nix {};
    dioxus-cli_0_8 = pkgs.callPackage ./dioxus-cli-0_8.nix {
      inherit rustPlatform;
      rustfmt = rustDeveloperToolchain;
      wasm-bindgen-cli_0_2_128 = wasmBindgenCli;
    };
    wasm-bindgen-cli-0_2_128 = wasmBindgenCli;
  }
  // pkgs.lib.optionalAttrs (pkgs.lib.elem pkgs.stdenv.hostPlatform.system [
    "x86_64-linux"
    "aarch64-linux"
  ]) {
    google-antigravity-cli = pkgs.callPackage ./google-antigravity-cli.nix {};
  }
