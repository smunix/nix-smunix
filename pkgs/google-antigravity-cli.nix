{
  autoPatchelfHook,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
}: let
  availableSources = {
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.6-5912685477494784/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-Xic4ttiLEGwpXY49qpajhuVFZl7Fj67ZTVl9KgvCfhac8fkTr4FILaxeCR1uMTn8s8MsYHmLX7q3UT2CMtz3hw==";
    };
    aarch64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.6-5912685477494784/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-aFssJfA2p69Ts8zKKsao0SALBwvFei4F+kV0J2xTjs/xn3Y8qXwjLWL8JCL+mNh2DFA/wxvUmp16LtPsEbupAg==";
    };
  };
  source = availableSources.${stdenv.hostPlatform.system} or (throw "google-antigravity-cli: unsupported system ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "google-antigravity-cli";
    version = "1.2.6";

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
