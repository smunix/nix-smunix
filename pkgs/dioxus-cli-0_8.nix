{
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
  wasm-bindgen-cli_0_2_121,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dioxus-cli";
  version = "0.8.0-alpha.1";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-4x9xTc9FW03ohEhDOe+wJ0EJ4yR8HWFmiEA+hvlLF7Q=";
  };

  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

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
    "--skip=serve::proxy::test"
    "--skip=test_harnesses::run_harness"
  ];

  postInstall = ''
    installShellCompletion --cmd dx \
      --bash <($out/bin/dx completions bash) \
      --fish <($out/bin/dx completions fish) \
      --zsh <($out/bin/dx completions zsh)
  '';

  postFixup = ''
    wrapProgram "$out/bin/dx" \
      --suffix PATH : ${
      lib.makeBinPath [
        esbuild
        wasm-bindgen-cli_0_2_121
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
