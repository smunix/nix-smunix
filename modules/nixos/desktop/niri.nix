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
  wallpaperDirectory = "${config.user.home}/Pictures/Wallpapers";
  wallpaper = "${wallpaperDirectory}/anime-girls_tea.jpg";
  noctaliaSettings = import ./niri/_noctalia-settings.nix {
    homeDirectory = config.user.home;
    inherit wallpaper wallpaperDirectory;
  };
in {
  imports = [inputs.noctalia.nixosModules.default];

  options.modules.desktop.niri.enable =
    lib.mkEnableOption "the Niri Wayland compositor with the Noctalia desktop shell";

  config = lib.mkIf cfg.enable {
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

      xdg.configFile = {
        "niri/config.kdl".source = ./niri/config.kdl;
        "qt6ct/qt6ct.conf".text = ''
          [Appearance]
          custom_palette=false
          icon_theme=Papirus-Dark
          standard_dialogs=default
          style=Fusion

          [Fonts]
          fixed="Maple Mono NF CN,8.5,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
          general="Maple Mono NF CN,8.5,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"

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
