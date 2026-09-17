{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.rust;
  defaultPolicy = import ../../../pkgs/rust-toolchain-policy.nix;
  effectiveChannel =
    if cfg.nightlyVersion != null
    then "nightly"
    else cfg.channel;
  effectiveVersion =
    if cfg.nightlyVersion != null
    then cfg.nightlyVersion
    else cfg.version;
  rustToolchain = pkgs.rust-bin.${effectiveChannel}.${effectiveVersion}.default.override {
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

    channel = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "nightly"
      ];
      default = defaultPolicy.channel;
      description = "rust-overlay release channel used across the host and by dependent development modules.";
    };

    version = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = defaultPolicy.version;
      description = "Pinned rust-overlay version for the selected channel, such as 1.98.1 for stable or a YYYY-MM-DD date for nightly.";
    };

    nightlyVersion = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
      description = "Deprecated compatibility option. When set, selects the nightly channel and overrides modules.develop.rust.version.";
    };

    targets = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [];
      apply = lib.unique;
      description = "Additional compilation targets included in the shared rust-overlay toolchain.";
    };

    resolvedChannel = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "nightly"
      ];
      readOnly = true;
      default = effectiveChannel;
      description = "Effective Rust release channel after applying the deprecated nightly compatibility option.";
    };

    resolvedVersion = lib.mkOption {
      type = lib.types.nonEmptyStr;
      readOnly = true;
      default = effectiveVersion;
      description = "Effective rust-overlay version shared by all enabled Rust consumers.";
    };

    toolchain = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = rustToolchain;
      description = "Resolved Rust toolchain package for the configured channel, version, components, and targets.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional (cfg.nightlyVersion != null) ''
      modules.develop.rust.nightlyVersion is deprecated; use channel = "nightly" and version = "${cfg.nightlyVersion}" instead.
    '';

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
        SMUNIX_RUST_CHANNEL = cfg.resolvedChannel;
        SMUNIX_RUST_VERSION = cfg.resolvedVersion;
      };
    };
  };
}
