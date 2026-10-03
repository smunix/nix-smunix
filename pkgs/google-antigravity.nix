{
  alsa-lib,
  asar,
  at-spi2-atk,
  at-spi2-core,
  atk,
  autoPatchelfHook,
  cairo,
  cups,
  dbus,
  expat,
  fetchurl,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  lib,
  libdrm,
  libGL,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  makeWrapper,
  mesa,
  nspr,
  nss,
  pango,
  stdenv,
  systemdLibs,
  udev,
}: let
  availableSources = {
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.19.1-6046815158665216/linux-x64/Antigravity.tar.gz";
      hash = "sha512-LgMi1/gHJiazDwnwyQ6W45C6NSRlNzzXNuGks4WJ1v+EMe3p3qs4fzl/KJLYmf1T1/TOkXENr5uOI+dfgYLBDg==";
    };
    aarch64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.19.1-6046815158665216/linux-arm/Antigravity.tar.gz";
      hash = "sha512-F2OTkiZs6NpqKenwrr2VIrXDNaTCkswSB05hspWls687cfm4N4rOjQLK9XWd7+NrO30GDhPjGC5BOJlmfdsZeQ==";
    };
  };
  source = availableSources.${stdenv.hostPlatform.system} or (throw "google-antigravity: unsupported system ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "google-antigravity";
    version = "2.19.1";

    src = fetchurl {
      inherit (source) url hash;
      name = "antigravity-hub-${stdenv.hostPlatform.system}.tar.gz";
    };

    sourceRoot = ".";

    nativeBuildInputs = [
      asar
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
      libx11
      libxcb
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxkbcommon
      libxrandr
      libxrender
      libxscrnsaver
      libxshmfence
      libxtst
      mesa
      nspr
      nss
      pango
      systemdLibs
      udev
    ];

    installPhase = ''
      runHook preInstall

      cd Antigravity-*

      libexec="$out/libexec/google-antigravity"
      install -d "$libexec"
      cp -a . "$libexec/"

      asar extract-file resources/app.asar icon.png
      install -Dm644 icon.png "$out/share/icons/hicolor/512x512/apps/antigravity.png"
      install -Dm644 icon.png "$out/share/pixmaps/antigravity.png"

      makeWrapper "$libexec/antigravity" "$out/bin/antigravity" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [libGL]}" \
        --set ELECTRON_OZONE_PLATFORM_HINT auto

      makeWrapper "$libexec/antigravity" "$out/bin/agy-hub" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [libGL]}" \
        --set ELECTRON_OZONE_PLATFORM_HINT auto

      mkdir -p "$out/share/applications"
      cat > "$out/share/applications/antigravity.desktop" << EOF
      [Desktop Entry]
      Name=Antigravity
      Comment=Google Antigravity 2.0 multi-agent orchestration platform
      Exec=antigravity %U
      Icon=antigravity
      Type=Application
      Categories=Development;Utility;
      StartupNotify=true
      StartupWMClass=Antigravity
      EOF

      runHook postInstall
    '';

    meta = {
      description = "Google Antigravity 2.0 multi-agent orchestration platform";
      homepage = "https://antigravity.google/product/antigravity-2/";
      license = lib.licenses.unfree;
      mainProgram = "antigravity";
      platforms = lib.attrNames availableSources;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
