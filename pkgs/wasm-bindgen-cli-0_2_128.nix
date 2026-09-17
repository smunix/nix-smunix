{
  fetchCrate,
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "wasm-bindgen-cli";
  version = "0.2.128";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-a7lcXJnnZkYReja+iUO7NqqrWyv3toxnUgQb8s4IS5s=";
  };

  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

  doCheck = false;

  meta = {
    description = "Command-line interface for wasm-bindgen";
    homepage = "https://wasm-bindgen.github.io/wasm-bindgen/";
    license = with lib.licenses; [asl20 mit];
    mainProgram = "wasm-bindgen";
    platforms = lib.platforms.unix;
  };
})
