{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.aya;
  rustCfg = config.modules.develop.rust;
  supportedSystem = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  rustToolchain = rustCfg.toolchain;
  ayaCargo = pkgs.writeShellScriptBin "aya-cargo" ''
    export PATH="${rustToolchain}/bin:${pkgs.bpf-linker-aya}/bin:$PATH"
    export RUSTC="${rustToolchain}/bin/rustc"
    export RUSTDOC="${rustToolchain}/bin/rustdoc"
    export RUST_SRC_PATH="${rustToolchain}/lib/rustlib/src/rust/library"
    exec "${rustToolchain}/bin/cargo" "$@"
  '';
  ayaRustc = pkgs.writeShellScriptBin "aya-rustc" ''
    exec "${rustToolchain}/bin/rustc" "$@"
  '';
in {
  options.modules.develop.aya = {
    enable = lib.mkEnableOption "Aya and eBPF development tools";

    vm.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the ebpf-vm launcher for the isolated Aya/eBPF NixOS laboratory.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = supportedSystem;
        message = "modules.develop.aya currently supports only x86_64-linux because the pinned bpf-linker artifact is architecture-specific.";
      }
      {
        assertion = rustCfg.enable;
        message = "modules.develop.aya requires modules.develop.rust.enable so both features share one configured nightly toolchain.";
      }
    ];

    user = {
      extraGroups = lib.mkAfter ["kvm"];
      packages =
        [
          ayaCargo
          ayaRustc
          pkgs.aya-tool
          pkgs.bpf-linker-aya
          pkgs.bpftools
          pkgs.bpftrace
          pkgs.llvmPackages.llvm
          pkgs.pahole
          pkgs.tcpdump
        ]
        ++ lib.optional cfg.vm.enable inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.ebpf-vm;
    };

    environment = {
      shellAliases.ebpf-cargo = "aya-cargo";
      variables = {
        AYA_RUST_TOOLCHAIN = "${rustToolchain}";
        AYA_RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
      };
    };
  };
}
