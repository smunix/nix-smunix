{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  cfg = config.modules.desktop.niri;
  niriPackages = inputs.niri.packages.${system};
  niriPackage = niriPackages."niri-${cfg.packageChannel}";
  xwaylandSatellitePackage = niriPackages."xwayland-satellite-${cfg.packageChannel}";
  noctaliaPackage = inputs.noctalia.packages.${system}.default;
  fontScale = config.modules.desktop.fonts.compact.factor;
  qtFontSize = 10.0 * fontScale;
  wallpaperDirectory = "${config.user.home}/Pictures/Wallpapers";
  wallpaper = "${wallpaperDirectory}/anime-girls_tea.jpg";
  noctaliaSettings = import ./niri/_noctalia-settings.nix {
    homeDirectory = config.user.home;
    idleLockEnabled = cfg.screenLock.enable;
    idleLockTimeout = cfg.screenLock.timeoutSeconds;
    idleScreenOffTimeout = cfg.screenLock.timeoutSeconds + cfg.screenLock.screenOffDelaySeconds;
    lockBeforeSuspend = cfg.screenLock.lockOnSuspend;
    inherit fontScale wallpaper wallpaperDirectory;
  };
  workspaceNames = [
    "shell"
    "internet"
    "viewers"
    "programming"
    "explorers"
    "chats"
    "dumpster"
  ];
  primaryWorkspaceOutput =
    if cfg.monitorLayout.primaryOutput == "external"
    then cfg.monitorLayout.external.connector
    else cfg.monitorLayout.internal.connector;
  workspaceConfig =
    lib.concatMapStringsSep "\n" (
      name:
        if cfg.monitorLayout.enable
        then ''
          workspace "${name}" {
              open-on-output "${primaryWorkspaceOutput}"
          }
        ''
        else ''workspace "${name}"''
    )
    workspaceNames;
  externalLayoutConfig =
    lib.optionalString cfg.monitorLayout.external.fullWidthColumns
    "    layout {\n        default-column-width { proportion 1.0; }\n    }\n";
  monitorConfig = lib.optionalString cfg.monitorLayout.enable ''
    // External portrait display on the left.
    output "${cfg.monitorLayout.external.connector}" {
        mode "${cfg.monitorLayout.external.mode}"
        scale ${toString cfg.monitorLayout.external.scale}
        transform "${cfg.monitorLayout.external.transform}"
        position x=${toString cfg.monitorLayout.external.position.x} y=${toString cfg.monitorLayout.external.position.y}

    ${externalLayoutConfig}    }

    // Built-in HiDPI panel on the right.
    output "${cfg.monitorLayout.internal.connector}" {
        mode "${cfg.monitorLayout.internal.mode}"
        scale ${toString cfg.monitorLayout.internal.scale}
        transform "${cfg.monitorLayout.internal.transform}"
        position x=${toString cfg.monitorLayout.internal.position.x} y=${toString cfg.monitorLayout.internal.position.y}
    }
  '';
  niriConfig = pkgs.writeText "niri-config.kdl" ''
    ${monitorConfig}
    ${workspaceConfig}
    ${builtins.readFile ./niri/config.kdl}
  '';
  gammastepManualFallbackConfig = pkgs.writeText "gammastep-manual-fallback.ini" ''
    [general]
    temp-day=${toString cfg.gammastep.dayTemperature}
    temp-night=${toString cfg.gammastep.nightTemperature}
    fade=1
    brightness-day=1.0
    brightness-night=1.0
    adjustment-method=wayland
    location-provider=manual

    [manual]
    lat=${toString cfg.gammastep.latitude}
    lon=${toString cfg.gammastep.longitude}
  '';
  gammastepAutoLocationLauncher = pkgs.writeShellScript "gammastep-niri-auto-location" ''
    set -u

    automatic_config="${config.user.home}/.config/gammastep/config.ini"

    if ${pkgs.networkmanager}/bin/nmcli radio wifi 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qx enabled; then
      attempt=1
      while [ "$attempt" -le 5 ]; do
        if ${pkgs.networkmanager}/bin/nmcli -t -f BSSID device wifi list --rescan yes 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -q .; then
          break
        fi
        attempt=$((attempt + 1))
        ${pkgs.coreutils}/bin/sleep 2
      done
    fi

    if ${pkgs.coreutils}/bin/timeout ${toString cfg.gammastep.locationTimeoutSeconds} \
      ${pkgs.gammastep}/bin/gammastep -p -c "$automatic_config" >/dev/null 2>&1; then
      exec ${pkgs.gammastep}/bin/gammastep -c "$automatic_config"
    fi

    ${lib.optionalString cfg.gammastep.fallbackToManual ''
      echo "Gammastep: GeoClue location unavailable; using configured manual fallback." >&2
      exec ${pkgs.gammastep}/bin/gammastep -c ${gammastepManualFallbackConfig}
    ''}

    echo "Gammastep: GeoClue location unavailable and no manual fallback is configured." >&2
    exit 1
  '';
in {
  imports = [inputs.noctalia.nixosModules.default];

  options.modules.desktop.niri = {
    enable =
      lib.mkEnableOption "the Niri Wayland compositor with the Noctalia desktop shell";

    packageChannel = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "unstable"
      ];
      default = "stable";
      description = "Which package channel from the pinned Niri flake to use.";
    };

    monitorLayout = {
      enable = lib.mkEnableOption "the configured external and internal Niri output layout";

      primaryOutput = lib.mkOption {
        type = lib.types.enum [
          "external"
          "internal"
        ];
        default = "internal";
        description = "Which configured output owns the persistent named workspaces when available.";
      };

      external = {
        connector = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "DP-5";
          description = "Connector name of the external portrait display.";
        };
        mode = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "2560x1440@59.91";
          description = "Mode selected for the external portrait display.";
        };
        scale = lib.mkOption {
          type = lib.types.numbers.between 0.1 10.0;
          default = 1;
          description = "Scale factor for the external portrait display.";
        };
        transform = lib.mkOption {
          type = lib.types.enum [
            "normal"
            "90"
            "180"
            "270"
            "flipped"
            "flipped-90"
            "flipped-180"
            "flipped-270"
          ];
          default = "90";
          description = "Counter-clockwise transform applied to the external display.";
        };
        position = {
          x = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "External display X position in logical pixels.";
          };
          y = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "External display Y position in logical pixels.";
          };
        };
        fullWidthColumns = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether new columns default to the full external output width.";
        };
      };

      internal = {
        connector = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "eDP-1";
          description = "Connector name of the built-in display.";
        };
        mode = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "3840x2400@59.99";
          description = "Mode selected for the built-in display.";
        };
        scale = lib.mkOption {
          type = lib.types.numbers.between 0.1 10.0;
          default = 2;
          description = "Scale factor for the built-in display.";
        };
        transform = lib.mkOption {
          type = lib.types.enum [
            "normal"
            "90"
            "180"
            "270"
            "flipped"
            "flipped-90"
            "flipped-180"
            "flipped-270"
          ];
          default = "normal";
          description = "Transform applied to the built-in display.";
        };
        position = {
          x = lib.mkOption {
            type = lib.types.int;
            default = 1440;
            description = "Built-in display X position in logical pixels.";
          };
          y = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "Built-in display Y position in logical pixels.";
          };
        };
      };
    };

    gammastep = {
      enable = lib.mkEnableOption "sunset-scheduled warm display colors in Niri";

      locationProvider = lib.mkOption {
        type = lib.types.enum [
          "manual"
          "geoclue2"
        ];
        default = "manual";
        description = "How Gammastep obtains the location used for solar scheduling.";
      };

      latitude = lib.mkOption {
        type = lib.types.nullOr (lib.types.numbers.between (-90.0) 90.0);
        default = null;
        description = "Latitude used by the manual provider or GeoClue fallback.";
      };

      longitude = lib.mkOption {
        type = lib.types.nullOr (lib.types.numbers.between (-180.0) 180.0);
        default = null;
        description = "Longitude used by the manual provider or GeoClue fallback.";
      };

      fallbackToManual = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to use the configured coordinates when GeoClue cannot determine a location.";
      };

      locationTimeoutSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 20;
        description = "Seconds to wait for GeoClue before selecting the manual fallback.";
      };

      dayTemperature = lib.mkOption {
        type = lib.types.ints.between 1000 25000;
        default = 6500;
        description = "Display color temperature in kelvin during daylight.";
      };

      nightTemperature = lib.mkOption {
        type = lib.types.ints.between 1000 25000;
        default = 3500;
        description = "Display color temperature in kelvin after sunset.";
      };
    };

    screenLock = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether Noctalia automatically locks the Niri session after inactivity.";
      };

      timeoutSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 600;
        description = "Seconds of inactivity before Noctalia locks the Niri session.";
      };

      screenOffDelaySeconds = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 60;
        description = "Seconds after automatic locking before Noctalia switches the displays off.";
      };

      lockOnSuspend = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether Noctalia locks the session before suspend.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.monitorLayout.enable || cfg.packageChannel == "unstable";
        message = "Niri per-output layout overrides require packageChannel = \"unstable\" with the pinned Niri flake.";
      }
      {
        assertion =
          !cfg.monitorLayout.enable
          || cfg.monitorLayout.external.connector != cfg.monitorLayout.internal.connector;
        message = "Niri external and internal outputs must use different connector names.";
      }
      {
        assertion =
          !cfg.gammastep.enable
          || (
            cfg.gammastep.locationProvider
            == "geoclue2"
            && !cfg.gammastep.fallbackToManual
          )
          || (cfg.gammastep.latitude != null && cfg.gammastep.longitude != null);
        message = "Niri Gammastep requires both latitude and longitude for manual location or fallback.";
      }
    ];

    programs = {
      niri = {
        enable = true;
        package = niriPackage;
      };

      noctalia = {
        enable = true;
        package = noctaliaPackage;
        systemd.enable = false;
        recommendedServices.enable = true;
      };

      dconf.enable = true;
    };

    security.polkit.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;

    services.geoclue2 =
      lib.mkIf (
        cfg.gammastep.enable && cfg.gammastep.locationProvider == "geoclue2"
      ) {
        enable = true;
        enableDemoAgent = true;
        enableNmea = false;
        enable3G = false;
        enableCDMA = false;
        enableModemGPS = false;
        enableWifi = true;
        appConfig.gammastep = {
          isAllowed = true;
          isSystem = true;
        };
      };

    systemd.user.services.geoclue-agent =
      lib.mkIf (
        cfg.gammastep.enable && cfg.gammastep.locationProvider == "geoclue2"
      ) {
        wantedBy = lib.mkForce ["niri.service"];
        after = ["niri.service"];
        partOf = ["niri.service"];
        unitConfig.ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
      };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        maple-mono.NF-CN-unhinted
        noto-fonts
        noto-fonts-color-emoji
      ];
      fontconfig.defaultFonts = {
        monospace = ["Maple Mono NF CN"];
        sansSerif = ["Noto Sans"];
        serif = ["Noto Serif"];
        emoji = ["Noto Color Emoji"];
      };
    };

    user.packages = with pkgs; [
      app2unit
      brightnessctl
      cliphist
      grim
      hyprpicker
      kdePackages.dolphin
      kdePackages.okular
      libnotify
      networkmanagerapplet
      pavucontrol
      playerctl
      qt6Packages.qt6ct
      satty
      slurp
      wf-recorder
      wireplumber
      wl-clipboard
      xterm
      xwaylandSatellitePackage
    ];

    hm = {
      imports = [inputs.noctalia.homeModules.default];

      home = {
        file."Pictures/Wallpapers/anime-girls_tea.jpg".source =
          ./niri/wallpapers/anime-girls_tea.jpg;

        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
          MOZ_WEBRENDER = "1";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          _JAVA_AWT_WM_NONREPARENTING = "1";
          QT_QPA_PLATFORM = "wayland;xcb";
          QT_QPA_PLATFORMTHEME = "qt6ct";
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          SDL_VIDEODRIVER = "wayland";
          GDK_BACKEND = "wayland";
        };

        pointerCursor = {
          name = "Bibata-Modern-Ice";
          package = pkgs.bibata-cursors;
          size = 24;
          gtk.enable = true;
          x11.enable = true;
        };
      };

      gtk = {
        enable = true;
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      programs.noctalia = {
        enable = true;
        package = noctaliaPackage;
        systemd.enable = false;
        checkConfig = false;
        settings = noctaliaSettings;
      };

      services.gammastep = lib.mkIf cfg.gammastep.enable {
        enable = true;
        provider = cfg.gammastep.locationProvider;
        latitude = cfg.gammastep.latitude;
        longitude = cfg.gammastep.longitude;
        temperature = {
          day = cfg.gammastep.dayTemperature;
          night = cfg.gammastep.nightTemperature;
        };
        settings.general = {
          adjustment-method = "wayland";
          brightness-day = "1.0";
          brightness-night = "1.0";
          fade = 1;
        };
      };

      systemd.user.services.gammastep = lib.mkIf cfg.gammastep.enable {
        Unit = {
          After = lib.mkForce (
            ["niri.service"]
            ++ lib.optional (cfg.gammastep.locationProvider == "geoclue2") "geoclue-agent.service"
          );
          PartOf = lib.mkForce ["niri.service"];
          ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
        };
        Install.WantedBy = lib.mkForce ["niri.service"];
        Service.ExecStart = lib.mkIf (
          cfg.gammastep.locationProvider == "geoclue2"
        ) (lib.mkForce gammastepAutoLocationLauncher);
      };

      xdg.configFile = {
        "niri/config.kdl".source = niriConfig;
        "qt6ct/qt6ct.conf".text = ''
          [Appearance]
          custom_palette=false
          icon_theme=Papirus-Dark
          standard_dialogs=default
          style=Fusion

          [Fonts]
          fixed="Maple Mono NF CN,${toString qtFontSize},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
          general="Maple Mono NF CN,${toString qtFontSize},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"

          [Interface]
          activate_item_on_single_click=1
          buttonbox_layout=0
          dialog_buttons_have_icons=1
          keyboard_scheme=2
          menus_have_icons=true
          show_shortcuts_in_context_menus=true
          toolbutton_style=4
          wheel_scroll_lines=3
        '';
      };
    };
  };
}
