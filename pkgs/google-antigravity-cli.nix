{
  autoPatchelfHook,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
}: let
  availableSources = {
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.15-5434575321694208/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-bS4u7aDK1urI6LLfESV9aEIQ+NOEou4BHcatDtrPoz4eycVUWJ9v9u8Gl/TDx3e6RrboRjlxHxczd8wVVMZ0Ng==";
    };
    aarch64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.15-5434575321694208/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-GZ5kGf11Sfopb1HGA1yeAkb57NObZiTEb/mkFvcrC2V5mZxpLJSZ0hip+IdG1g7njQ9ZKzHI+ri+hbDUBTOZHQ==";
    };
  };
  source = availableSources.${stdenv.hostPlatform.system} or (throw "google-antigravity-cli: unsupported system ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "google-antigravity-cli";
    version = "1.2.15";

    src = fetchurl source;
    sourceRoot = ".";

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    installPhase = ''
      runHook preInstall

      install -Dm755 antigravity "$out/libexec/google-antigravity-cli/antigravity"
      makeWrapper "$out/libexec/google-antigravity-cli/antigravity" "$out/bin/agy" \
        --set AGY_CLI_DISABLE_AUTO_UPDATE true

      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      test "$($out/bin/agy --version)" = "${finalAttrs.version}"
      runHook postInstallCheck
    '';

    meta = {
      description = "Terminal client for Google Antigravity agents";
      homepage = "https://antigravity.google/product/antigravity-cli/";
      license = lib.licenses.unfree;
      mainProgram = "agy";
      platforms = lib.attrNames availableSources;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  })
