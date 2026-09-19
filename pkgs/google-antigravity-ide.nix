{
  autoPatchelfHook,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
  # Electron / Chromium runtime dependencies
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  udev,
  xorg,
}: let
  availableSources = {
    x86_64-linux = {
      url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz";
      hash = "sha512-QOUhQoi8MwqgdGficH4Tzrt7VQN5kzmPzUIfJY02/IVSQU9jlsfgD7b8vQpwicTb7T+J9E5NJ2Nypk31UUfKUA==";
    };
    aarch64-linux = {
      url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-arm/Antigravity%20IDE.tar.gz";
      hash = "sha512-ElTfSVvh65a+3J8jMv9qgi0i3OmGgkphDrLI5qTcdhZu8s4BF0Qx0nObYobGhljoovSy+Huq3AoHDvRI7f81wQ==";
    };
  };
  source = availableSources.${stdenv.hostPlatform.system} or (throw "google-antigravity-ide: unsupported system ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "google-antigravity-ide";
    version = "2.5.5";

    src = fetchurl {
      inherit (source) url hash;
      name = "antigravity-ide-${stdenv.hostPlatform.system}.tar.gz";
    };

    # The tarball extracts to "Antigravity IDE/" (with a space)
    sourceRoot = "Antigravity IDE";

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libGL
      libxkbcommon
      mesa
      nspr
      nss
      pango
      udev
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libxcb
      xorg.libxshmfence
    ];

    installPhase = ''
      runHook preInstall

      libexec="$out/libexec/google-antigravity-ide"
      install -d "$libexec"
      cp -a . "$libexec/"

      install -Dm644 resources/app/resources/linux/code.png \
        "$out/share/icons/hicolor/512x512/apps/antigravity-ide.png"

      makeWrapper "$libexec/antigravity-ide" "$out/bin/antigravity-ide" \
        --set ELECTRON_OZONE_PLATFORM_HINT auto

      # Short alias consistent with the agy CLI naming convention.
      makeWrapper "$libexec/antigravity-ide" "$out/bin/agy-ide" \
        --set ELECTRON_OZONE_PLATFORM_HINT auto

      mkdir -p "$out/share/applications"
      cat > "$out/share/applications/antigravity-ide.desktop" << EOF
      [Desktop Entry]
      Name=Antigravity IDE
      Comment=Google Antigravity standalone IDE
      Exec=antigravity-ide %F
      Icon=antigravity-ide
      Type=Application
      Categories=Development;IDE;
      MimeType=text/plain;inode/directory;
      StartupNotify=true
      StartupWMClass=antigravity-ide
      EOF

      runHook postInstall
    '';

    meta = {
      description = "Google Antigravity standalone IDE with AI-assisted coding";
      homepage = "https://antigravity.google/product/antigravity-ide/";
      license = lib.licenses.unfree;
      mainProgram = "agy-ide";
      platforms = lib.attrNames availableSources;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  })
