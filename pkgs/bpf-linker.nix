{
  fetchurl,
  lib,
  stdenvNoCC,
  zstd,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bpf-linker";
  version = "0.11.1";

  src = fetchurl {
    url = "https://github.com/aya-rs/bpf-linker/releases/download/v${finalAttrs.version}/bpf-linker-x86_64-unknown-linux-musl.tar.zst";
    hash = "sha256-4FimrsyeZfpMl3spio5Lc4Qk12KXaf01Lu1An7V+Fug=";
  };

  nativeBuildInputs = [zstd];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tar -xf "$src" --use-compress-program=unzstd
    install -Dm755 bpf-linker "$out/bin/bpf-linker"

    runHook postInstall
  '';

  meta = {
    description = "Static BPF linker matched to the pinned Aya Rust nightly";
    homepage = "https://aya-rs.dev";
    license = with lib.licenses; [asl20 mit];
    mainProgram = "bpf-linker";
    platforms = ["x86_64-linux"];
  };
})
