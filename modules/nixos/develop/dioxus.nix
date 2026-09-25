{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.develop.dioxus;
  rustCfg = config.modules.develop.rust;
  primaryUser = config.user.name;

  androidRustTargets = [
    "aarch64-linux-android"
    "armv7-linux-androideabi"
    "i686-linux-android"
    "x86_64-linux-android"
  ];

  desktopPackages =
    (with pkgs; [
      dbus
      gtk3
      libayatana-appindicator
      librsvg
      openssl
      webkitgtk_4_1
      xdotool
    ])
    ++ [cfg.desktop.libclangPackage];
  libclangLibraryPath = "${lib.getLib cfg.desktop.libclangPackage}/lib";
  desktopPackageClosure = lib.closePropagation desktopPackages;
  desktopRuntimeLibraries = map lib.getLib desktopPackageClosure;
  desktopDevelopmentOutputs = map lib.getDev desktopPackageClosure;
  desktopRuntimeLibraryPath = lib.makeLibraryPath desktopRuntimeLibraries;
  desktopNativeLibraryPath = lib.concatStringsSep ":" [
    desktopRuntimeLibraryPath
    (lib.makeSearchPath "lib" desktopDevelopmentOutputs)
  ];
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
      desktopRuntimeLibraryPath
      "--prefix"
      "XDG_DATA_DIRS"
      ":"
      (lib.makeSearchPath "share" desktopPackageClosure)
      "--prefix"
      "GIO_EXTRA_MODULES"
      ":"
      (lib.makeSearchPath "lib/gio/modules" desktopPackageClosure)
      "--set"
      "LIBCLANG_PATH"
      libclangLibraryPath
      "--prefix"
      "LIBRARY_PATH"
      ":"
      desktopNativeLibraryPath
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
  dioxusServe = pkgs.writeShellScriptBin "dioxus-serve" ''
    exec "${dioxusCli}/bin/dx" serve \
      --addr ${lib.escapeShellArg cfg.developmentServer.address} \
      --port ${toString cfg.developmentServer.port} \
      "$@"
  '';
  dioxusServeLan = pkgs.writeShellScriptBin "dioxus-serve-lan" ''
    exec "${dioxusServe}/bin/dioxus-serve" "$@"
  '';
  caddyCfg = cfg.developmentServer.caddy;
  caddyNetworkInterface =
    if caddyCfg.networkInterface == null
    then "dioxus-caddy-interface-not-configured"
    else caddyCfg.networkInterface;
  caddyBackendAddress =
    if lib.hasInfix ":" cfg.developmentServer.address
    then "[${cfg.developmentServer.address}]"
    else cfg.developmentServer.address;
  caddySiteAddress =
    if caddyCfg.hostName == null
    then "{$DIOXUS_CADDY_HOST}"
    else caddyCfg.hostName;
  caddyConfig = pkgs.writeText "dioxus-caddy.Caddyfile" ''
    ${lib.optionalString (caddyCfg.tlsMode == "internal" || caddyCfg.acmeEmail != null) ''
      {
        ${lib.optionalString (caddyCfg.tlsMode == "internal") "skip_install_trust"}
        ${lib.optionalString (caddyCfg.tlsMode == "public" && caddyCfg.acmeEmail != null) "email ${caddyCfg.acmeEmail}"}
      }
    ''}
    http://${caddySiteAddress} {
      bind {$DIOXUS_CADDY_BIND}
      redir https://${caddySiteAddress}{uri}
    }

    ${caddySiteAddress} {
      bind {$DIOXUS_CADDY_BIND}
      ${lib.optionalString (caddyCfg.tlsMode == "internal") "tls internal"}
      reverse_proxy ${caddyBackendAddress}:${toString cfg.developmentServer.port}

      ${lib.optionalString caddyCfg.securityHeaders ''
      header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
      }
    ''}
      ${lib.optionalString caddyCfg.compression "encode zstd gzip"}
      ${caddyCfg.extraConfig}
    }
  '';
  caddyAddressCommand = ''
    ${pkgs.iproute2}/bin/ip -4 -o address show \
      dev ${lib.escapeShellArg caddyNetworkInterface} scope global \
      | ${pkgs.gawk}/bin/awk 'NR == 1 { split($4, address, "/"); print address[1] }'
  '';
  dioxusCaddyAddress = pkgs.writeShellScriptBin "dioxus-caddy-address" ''
    set -eu
    address="$(${caddyAddressCommand})"
    if [ -z "$address" ]; then
      echo "No global IPv4 address is active on ${caddyNetworkInterface}." >&2
      exit 1
    fi
    printf 'https://%s\n' ${
      if caddyCfg.hostName == null
      then "\"$address\""
      else lib.escapeShellArg caddyCfg.hostName
    }
  '';
  caddyLauncher = pkgs.writeShellScript "dioxus-caddy-launch" ''
    set -eu
    address="$(${caddyAddressCommand})"
    if [ -z "$address" ]; then
      echo "Dioxus Caddy: ${caddyNetworkInterface} has no global IPv4 address." >&2
      exit 1
    fi

    export DIOXUS_CADDY_BIND="$address"
    export DIOXUS_CADDY_HOST=${
      if caddyCfg.hostName == null
      then "\"$address\""
      else lib.escapeShellArg caddyCfg.hostName
    }
    export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    mkdir -p "$XDG_DATA_HOME/caddy" "$XDG_CONFIG_HOME/caddy"

    echo "Dioxus Caddy: serving https://$DIOXUS_CADDY_HOST through $address on ${caddyNetworkInterface}." >&2
    exec /run/wrappers/bin/dioxus-caddy run \
      --config ${caddyConfig} \
      --adapter caddyfile
  '';
  caddyUserSystemctl = "${config.systemd.package}/bin/systemctl --user --machine=${primaryUser}@.host";
  caddyDispatcher = pkgs.writeShellScript "dioxus-caddy-network-dispatcher" ''
    set -eu

    interface=${lib.escapeShellArg caddyNetworkInterface}
    [ "''${1:-}" = "$interface" ] || exit 0

    stop_caddy() {
      ${caddyUserSystemctl} stop dioxus-caddy.service >/dev/null 2>&1 || true
    }

    case "''${2:-}" in
      up|dhcp4-change|reapply)
        address="$(${caddyAddressCommand})"
        if [ -z "$address" ]; then
          stop_caddy
          exit 0
        fi

        uid="$(${pkgs.coreutils}/bin/id -u ${lib.escapeShellArg primaryUser})"
        ${config.systemd.package}/bin/systemctl start "user@$uid.service"
        ${caddyUserSystemctl} daemon-reload
        ${caddyUserSystemctl} reset-failed dioxus-caddy.service || true
        ${caddyUserSystemctl} restart dioxus-caddy.service
        ;;
      pre-down|down)
        stop_caddy
        ;;
    esac
  '';

  androidEnvironment = pkgs.androidenv.override {
    licenseAccepted = true;
  };
  effectivePlatformVersions =
    if cfg.android.platformVersion != null
    then [cfg.android.platformVersion]
    else cfg.android.platformVersions;
  effectiveBuildToolsVersions =
    if cfg.android.buildToolsVersion != null
    then [cfg.android.buildToolsVersion]
    else cfg.android.buildToolsVersions;
  androidPackages = androidEnvironment.composeAndroidPackages {
    platformVersions = effectivePlatformVersions;
    buildToolsVersions = effectiveBuildToolsVersions;
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

    desktop.libclangPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llvmPackages.libclang;
      defaultText = lib.literalExpression "pkgs.llvmPackages.libclang";
      description = "Libclang package exposed to Dioxus hot-patching and its native fat-binary linker.";
    };

    developmentServer = {
      enable = lib.mkEnableOption "a configured Dioxus development-server helper";

      address = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "0.0.0.0";
        description = "IP address used by dioxus-serve. Use 127.0.0.1 when Caddy is the only intended network entry point.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "TCP port used by the Dioxus serve helpers and optionally opened in the NixOS firewall.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open the configured TCP development-server port on the NixOS firewall.";
      };

      caddy = {
        enable = lib.mkEnableOption "Caddy HTTPS reverse proxying for the Dioxus development server";

        hostName = lib.mkOption {
          type = lib.types.nullOr (lib.types.strMatching "[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?");
          default = null;
          example = "192.168.1.50";
          description = "Optional fixed IPv4 address or DNS host name used as the Caddy HTTPS site address. When null, the active IPv4 address of networkInterface is discovered at service start.";
        };

        networkInterface = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = null;
          example = "wlp0s20f3";
          description = "NetworkManager interface whose successful connection starts Caddy and whose active global IPv4 address Caddy binds.";
        };

        tlsMode = lib.mkOption {
          type = lib.types.enum [
            "internal"
            "public"
          ];
          default = "internal";
          description = "Use Caddy's internal CA for a LAN address, or automatic public ACME certificates for a public DNS name.";
        };

        acmeEmail = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "admin@example.com";
          description = "Optional ACME account email used by Caddy in public TLS mode.";
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Open TCP ports 80 and 443 plus UDP port 443 for Caddy redirects, HTTPS, and HTTP/3.";
        };

        securityHeaders = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Add HSTS, nosniff, frame-denial, and strict-origin referrer headers to proxied responses.";
        };

        compression = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable zstd and gzip response compression in Caddy.";
        };

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Additional Caddyfile directives appended to the generated Dioxus virtual host.";
        };
      };
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

      platformVersions = lib.mkOption {
        type = lib.types.listOf lib.types.nonEmptyStr;
        default = [
          "34"
          "35"
        ];
        description = "Android SDK platform versions included in the declarative SDK.";
      };

      buildToolsVersions = lib.mkOption {
        type = lib.types.listOf lib.types.nonEmptyStr;
        default = [
          "34.0.0"
          "35.0.0"
        ];
        description = "Android SDK Build Tools versions included in the declarative SDK.";
      };

      platformVersion = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = null;
        description = "Deprecated compatibility option. When set, restricts platformVersions to only this version.";
      };

      buildToolsVersion = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = null;
        description = "Deprecated compatibility option. When set, restricts buildToolsVersions to only this version.";
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
        {
          assertion = !caddyCfg.enable || cfg.developmentServer.enable;
          message = "modules.develop.dioxus.developmentServer.caddy requires developmentServer.enable.";
        }
        {
          assertion = !caddyCfg.enable || lib.elem cfg.developmentServer.address ["127.0.0.1" "::1"];
          message = "modules.develop.dioxus.developmentServer.caddy requires the Dioxus backend address to be 127.0.0.1 or ::1 so Caddy is the only network entry point.";
        }
        {
          assertion = !caddyCfg.enable || !cfg.developmentServer.openFirewall;
          message = "modules.develop.dioxus.developmentServer.openFirewall must be false when Caddy is enabled; expose only Caddy's TLS ports instead.";
        }
        {
          assertion = !caddyCfg.enable || caddyCfg.networkInterface != null;
          message = "modules.develop.dioxus.developmentServer.caddy.networkInterface must be set when Caddy is enabled.";
        }
        {
          assertion = !caddyCfg.enable || config.networking.networkmanager.enable;
          message = "modules.develop.dioxus.developmentServer.caddy requires NetworkManager for connection-triggered user-service control.";
        }
        {
          assertion = !caddyCfg.enable || caddyCfg.hostName != null || caddyCfg.tlsMode == "internal";
          message = "Dynamic interface-address Caddy sites require tlsMode = \"internal\"; public TLS requires a fixed DNS hostName.";
        }
      ];

      user.packages = [dioxusCli];
    }

    (lib.mkIf cfg.developmentServer.enable {
      user.packages = [
        dioxusServe
        dioxusServeLan
      ];
      networking.firewall.allowedTCPPorts = lib.optional cfg.developmentServer.openFirewall cfg.developmentServer.port;
      environment.variables =
        {
          DIOXUS_DEVSERVER_ADDR = cfg.developmentServer.address;
          DIOXUS_DEVSERVER_PORT = toString cfg.developmentServer.port;
        }
        // lib.optionalAttrs caddyCfg.enable {
          DIOXUS_CADDY_CONFIG = caddyConfig;
          DIOXUS_CADDY_INTERFACE = caddyNetworkInterface;
        };
    })

    (lib.mkIf (cfg.developmentServer.enable && caddyCfg.enable) {
      environment.systemPackages = [pkgs.caddy];
      user.packages = [dioxusCaddyAddress];

      users.users.${primaryUser}.linger = true;

      security.wrappers.dioxus-caddy = {
        source = "${pkgs.caddy}/bin/caddy";
        owner = "root";
        group = "wheel";
        permissions = "0510";
        capabilities = "cap_net_bind_service+ep";
      };

      systemd.user.services.dioxus-caddy = {
        description = "Caddy TLS proxy for the Dioxus development server";
        unitConfig = {
          StartLimitBurst = 3;
          StartLimitIntervalSec = 60;
        };
        serviceConfig = {
          Type = "simple";
          ExecStart = caddyLauncher;
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      networking.firewall.interfaces.${caddyNetworkInterface} = {
        allowedTCPPorts = lib.optionals caddyCfg.openFirewall [
          80
          443
        ];
        allowedUDPPorts = lib.optional caddyCfg.openFirewall 443;
      };

      networking.networkmanager.dispatcherScripts = [
        {
          source = caddyDispatcher;
          type = "basic";
        }
        {
          source = caddyDispatcher;
          type = "pre-down";
        }
      ];

      systemd.services.dioxus-caddy-network-sync = {
        description = "Synchronize the Dioxus Caddy user service with Wi-Fi state";
        wantedBy = ["multi-user.target"];
        wants = ["NetworkManager.service"];
        after = [
          "NetworkManager.service"
          "linger-users.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${caddyDispatcher} ${lib.escapeShellArg caddyNetworkInterface} up";
        };
      };
    })

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
