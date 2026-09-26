{
  autoPatchelfHook,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
}: let
  availableSources = {
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.11-6016716732497920/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-yhLCYjQ/KaK4dCPR/x5CRJiek243/h+OVgVrD5HNAvk/EzMhIpzjXIbC2EuXfpGZN6P9lDDP12mhbWsD7eJQgQ==";
    };
    aarch64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.11-6016716732497920/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-T9T44ZYOAAt4A9ojZcZKczZ38e2A/twcNEMxl48SkXHdHRKOhSVaTy8NOILPCXs4l8wnBLT69NNmn348acwwEg==";
    };
  };
  source = availableSources.${stdenv.hostPlatform.system} or (throw "google-antigravity-cli: unsupported system ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "google-antigravity-cli";
    version = "1.2.11";

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
