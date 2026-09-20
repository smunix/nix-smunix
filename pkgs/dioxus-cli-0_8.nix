{
  binaryen,
  cacert,
  esbuild,
  fetchCrate,
  installShellFiles,
  lib,
  makeWrapper,
  openssl,
  pkg-config,
  rustPlatform,
  rustfmt,
  stdenv,
  wasm-bindgen-cli_0_2_128,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dioxus-cli";
  version = "0.8.0-alpha.1";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-4x9xTc9FW03ohEhDOe+wJ0EJ4yR8HWFmiEA+hvlLF7Q=";
  };

  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

  patches = [
    # Injects $LIBRARY_PATH entries as explicit -L flags into Dioxus's custom
    # fat-linking and incremental thin-linking passes for NixOS C library resolution.
    ./patches/dioxus-cli-0_8-library-path.patch
  ];

  buildFeatures = [
    "no-downloads"
    "disable-telemetry"
  ];

  env.OPENSSL_NO_VENDOR = 1;

  nativeBuildInputs = [
    cacert
    installShellFiles
    makeWrapper
    pkg-config
  ];

  buildInputs = [openssl];
  nativeCheckInputs = [rustfmt];

  checkFlags = [
    # Binds 127.0.0.1:0 for reverse proxy testing; fails in hermetic build sandboxes
    "--skip=serve::proxy::test"
    # Requires upstream Dioxus monorepo workspace dependencies absent in crates.io tarball
    "--skip=test_harnesses::run_harness"
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    $out/bin/dx completions bash > dx.bash
    $out/bin/dx completions fish > dx.fish
    $out/bin/dx completions zsh > _dx

    installShellCompletion dx.bash dx.fish _dx
  '';

  postFixup = ''
    wrapProgram "$out/bin/dx" \
      --suffix PATH : ${
      lib.makeBinPath [
        binaryen
        esbuild
        wasm-bindgen-cli_0_2_128
      ]
    }
  '';

  meta = {
    description = "Dioxus 0.8-series CLI for desktop, web, and mobile applications";
    homepage = "https://dioxus.dev";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "dx";
    platforms = lib.platforms.all;
  };
})
