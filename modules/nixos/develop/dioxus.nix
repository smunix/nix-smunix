{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.dioxus;
  rustCfg = config.modules.develop.rust;

  androidRustTargets = [
    "aarch64-linux-android"
    "armv7-linux-androideabi"
    "i686-linux-android"
    "x86_64-linux-android"
  ];

  desktopPackages = with pkgs; [
    dbus
    gtk3
    libayatana-appindicator
    librsvg
    openssl
    webkitgtk_4_1
    xdotool
  ];
  desktopPackageClosure = lib.closePropagation desktopPackages;
  desktopRuntimeLibraries = map lib.getLib desktopPackageClosure;
  desktopDevelopmentOutputs = map lib.getDev desktopPackageClosure;
  desktopPkgConfigPath = lib.concatStringsSep ":" [
    (lib.makeSearchPath "lib/pkgconfig" desktopDevelopmentOutputs)
    (lib.makeSearchPath "share/pkgconfig" desktopDevelopmentOutputs)
  ];
  dioxusWrapperArgs =
    lib.optionals cfg.desktop.enable [
      "--prefix"
      "PKG_CONFIG_PATH"
      ":"
      desktopPkgConfigPath
      "--prefix"
      "LD_LIBRARY_PATH"
      ":"
      (lib.makeLibraryPath desktopRuntimeLibraries)
      "--prefix"
      "XDG_DATA_DIRS"
      ":"
      (lib.makeSearchPath "share" desktopPackageClosure)
      "--prefix"
      "GIO_EXTRA_MODULES"
      ":"
      (lib.makeSearchPath "lib/gio/modules" desktopPackageClosure)
    ]
    ++ lib.optionals cfg.web.enable [
      "--prefix"
      "PATH"
      ":"
      (lib.makeBinPath [
        cfg.web.wasmBindgenCliPackage
        cfg.web.wasmOptPackage
      ])
    ];
  dioxusCli =
    if dioxusWrapperArgs != []
    then
      pkgs.symlinkJoin {
        name = "dioxus-cli-${cfg.package.version}-configured";
        paths = [cfg.package];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram "$out/bin/dx" ${lib.escapeShellArgs dioxusWrapperArgs}
        '';
      }
    else cfg.package;

  androidEnvironment = pkgs.androidenv.override {
    licenseAccepted = true;
  };
  androidPackages = androidEnvironment.composeAndroidPackages {
    platformVersions = [cfg.android.platformVersion];
    buildToolsVersions = [cfg.android.buildToolsVersion];
    includeCmake = true;
    cmakeVersions = [cfg.android.cmakeVersion];
    includeNDK = true;
    ndkVersions = [cfg.android.ndkVersion];
    inherit (cfg.android) includeEmulator;
    includeSystemImages = cfg.android.includeSystemImage;
    systemImageTypes = [cfg.android.systemImageType];
    abiVersions = [cfg.android.emulatorAbi];
  };
  androidSdk = androidPackages.androidsdk;
  androidHome = "${androidSdk}/libexec/android-sdk";
  androidNdkHome = "${androidHome}/ndk/${cfg.android.ndkVersion}";
in {
  options.modules.develop.dioxus = {
    enable = lib.mkEnableOption "Dioxus desktop and Android development tools";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.dioxus-cli_0_8;
      defaultText = lib.literalExpression "pkgs.dioxus-cli_0_8";
      description = "Pinned Dioxus 0.8-series CLI package that provides the dx command.";
    };

    desktop.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install and configure Linux dependencies for Dioxus desktop applications.";
    };

    web = {
      enable = lib.mkEnableOption "Dioxus web development tools";

      rustTarget = lib.mkOption {
        type = lib.types.enum ["wasm32-unknown-unknown"];
        default = "wasm32-unknown-unknown";
        description = "Rust WebAssembly target added to the shared rust-overlay toolchain.";
      };

      wasmBindgenCliPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.wasm-bindgen-cli_0_2_128;
        defaultText = lib.literalExpression "pkgs.wasm-bindgen-cli_0_2_128";
        description = "Exact wasm-bindgen CLI package selected to match the application's wasm-bindgen crate version.";
      };

      wasmOptPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.binaryen;
        defaultText = lib.literalExpression "pkgs.binaryen";
        description = "Binaryen package that supplies wasm-opt for Dioxus web builds.";
      };
    };

    android = {
      enable = lib.mkEnableOption "Dioxus Android development tools";

      installStudio = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Android Studio alongside the declarative SDK and NDK.";
      };

      platformVersion = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "35";
        description = "Android SDK platform version included in the declarative SDK.";
      };

      buildToolsVersion = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "35.0.0";
        description = "Android SDK Build Tools version.";
      };

      ndkVersion = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "27.2.12479018";
        description = "Android NDK side-by-side version.";
      };

      cmakeVersion = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "3.22.1";
        description = "Android SDK CMake version.";
      };

      includeEmulator = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Include the Android emulator in the SDK composition.";
      };

      includeSystemImage = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Include an Android emulator system image.";
      };

      systemImageType = lib.mkOption {
        type = lib.types.enum [
          "default"
          "google_apis"
          "google_apis_playstore"
        ];
        default = "google_apis";
        description = "Android emulator system-image channel.";
      };

      emulatorAbi = lib.mkOption {
        type = lib.types.enum [
          "x86"
          "x86_64"
          "armeabi-v7a"
          "arm64-v8a"
        ];
        default = "x86_64";
        description = "Android emulator system-image ABI.";
      };

      javaPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.jdk17;
        defaultText = lib.literalExpression "pkgs.jdk17";
        description = "Java development kit used by Android and Gradle tooling.";
      };

      rustTargets = lib.mkOption {
        type = lib.types.listOf (lib.types.enum androidRustTargets);
        default = androidRustTargets;
        apply = lib.unique;
        description = "Rust Android targets added to the shared rust-overlay toolchain.";
      };

      sdkPackage = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        default = androidSdk;
        description = "Resolved declarative Android SDK, NDK, CMake, emulator, and system-image package.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = rustCfg.enable;
          message = "modules.develop.dioxus requires modules.develop.rust.enable so Dioxus uses the shared configured Rust toolchain.";
        }
        {
          assertion = !cfg.android.enable || cfg.android.rustTargets != [];
          message = "modules.develop.dioxus.android.rustTargets must contain at least one target when Android support is enabled.";
        }
        {
          assertion = !cfg.android.includeSystemImage || cfg.android.includeEmulator;
          message = "modules.develop.dioxus.android.includeSystemImage requires includeEmulator.";
        }
      ];

      user.packages = [dioxusCli];
    }

    (lib.mkIf cfg.desktop.enable {
      user.packages =
        [
          pkgs.clang
          pkgs.file
          pkgs.gnumake
          pkgs.lld
          pkgs.pkg-config
        ]
        ++ desktopPackages;
    })

    (lib.mkIf cfg.web.enable {
      modules.develop.rust.targets = lib.mkAfter [cfg.web.rustTarget];
      user.packages = [
        cfg.web.wasmBindgenCliPackage
        cfg.web.wasmOptPackage
      ];
    })

    (lib.mkIf cfg.android.enable {
      modules.develop.rust.targets = lib.mkAfter cfg.android.rustTargets;

      user = {
        extraGroups = lib.mkAfter ["kvm"];
        packages =
          [
            cfg.android.javaPackage
            cfg.android.sdkPackage
          ]
          ++ lib.optional cfg.android.installStudio pkgs.android-studio;
      };

      environment.variables = {
        ANDROID_HOME = androidHome;
        ANDROID_SDK_ROOT = androidHome;
        ANDROID_NDK_HOME = androidNdkHome;
        ANDROID_NDK_ROOT = androidNdkHome;
        NDK_HOME = androidNdkHome;
        JAVA_HOME = cfg.android.javaPackage.home;
      };
    })
  ]);
}
