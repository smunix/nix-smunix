{
  bpftools,
  fetchFromGitHub,
  lib,
  llvmPackages,
  makeWrapper,
  rust-bindgen,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "aya-tool";
  version = "0.1.0-unstable-2026-09-16";

  src = fetchFromGitHub {
    owner = "aya-rs";
    repo = "aya";
    rev = "c0f994075e632836ab3a0667633ef35d66939a32";
    hash = "sha256-KZZiG7NskrE764TjB2umoCnI90+tPDOV/RdUg/ToARg=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";
  cargoBuildFlags = [
    "--package"
    "aya-tool"
  ];
  doCheck = false;

  nativeBuildInputs = [
    makeWrapper
    rustPlatform.bindgenHook
  ];

  postInstall = ''
    wrapProgram "$out/bin/aya-tool" \
      --set LIBCLANG_PATH "${lib.getLib llvmPackages.libclang}/lib" \
      --prefix PATH : "${lib.makeBinPath [
      bpftools
      rust-bindgen
    ]}"
  '';

  meta = {
    description = "Generate Rust bindings for Linux kernel types used by Aya eBPF programs";
    homepage = "https://aya-rs.dev";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "aya-tool";
    platforms = lib.platforms.linux;
  };
}
