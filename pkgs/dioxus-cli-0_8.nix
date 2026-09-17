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

  buildFeatures = [
    "no-downloads"
    "disable-telemetry"
  ];

  env.OPENSSL_NO_VENDOR = 1;

  postPatch = ''
    substituteInPlace src/build/link.rs \
      --replace-fail \
        '        out_args.extend(out_arg.iter().map(Into::into));' \
        '        out_args.extend(out_arg.iter().map(Into::into));

        // Make every Nix-provided native library directory explicit for incremental linking.
        if cfg!(target_os = "linux") {
            if let Some(library_path) = std::env::var_os("LIBRARY_PATH") {
                out_args.extend(std::env::split_paths(&library_path).map(|path| {
                    format!("-L{}", path.display()).into()
                }));
            }
        }'

    substituteInPlace src/build/link.rs \
      --replace-fail \
        '        tracing::trace!("Fat linking with args: {:?} {:#?}", linker, args);' \
        '        // Make every Nix-provided native library directory explicit for full fat linking.
        if cfg!(target_os = "linux") {
            if let Some(library_path) = std::env::var_os("LIBRARY_PATH") {
                for path in std::env::split_paths(&library_path) {
                    let search_arg = format!("-L{}", path.display());
                    if !args.contains(&search_arg) {
                        args.push(search_arg);
                    }
                }
            }
        }

        tracing::trace!("Fat linking with args: {:?} {:#?}", linker, args);'
  '';

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
