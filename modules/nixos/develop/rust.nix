{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.rust;
  rustToolchain = pkgs.rust-bin.nightly.${cfg.nightlyVersion}.default.override {
    targets = cfg.targets;
    extensions = [
      "rust-src"
      "rustfmt"
      "clippy"
      "rust-analyzer"
    ];
  };
in {
  options.modules.develop.rust = {
    enable = lib.mkEnableOption "Rust development tools";

    nightlyVersion = lib.mkOption {
      type = lib.types.str;
      default = "2026-07-15";
      description = "Pinned rust-overlay nightly version used across the host and by dependent development modules such as Aya.";
    };

    targets = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [];
      apply = lib.unique;
      description = "Additional compilation targets included in the shared rust-overlay toolchain.";
    };

    toolchain = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = rustToolchain;
      description = "Resolved Rust nightly toolchain package for the configured version.";
    };
  };

  config = lib.mkIf cfg.enable {
    user.packages = [
      cfg.toolchain
      pkgs.cargo-generate
    ];

    environment = {
      shellAliases = {
        ca = "cargo";
        rs = "rustc";
      };
      variables = {
        RUST_SRC_PATH = "${cfg.toolchain}/lib/rustlib/src/rust/library";
      };
    };
  };
}
