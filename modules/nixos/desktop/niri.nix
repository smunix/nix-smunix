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
        package = niriPackages.niri-stable;
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
      niriPackages.xwayland-satellite-stable
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
        "niri/config.kdl".source = ./niri/config.kdl;
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
