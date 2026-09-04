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
in {
  options.modules.desktop.niri.enable =
    lib.mkEnableOption "the Niri Wayland compositor";

  config = lib.mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = niriPackages.niri-stable;
    };

    programs.dconf.enable = true;
    security.polkit.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    user.packages = with pkgs; [
      brightnessctl
      fuzzel
      grim
      libnotify
      mako
      playerctl
      satty
      slurp
      swaybg
      swaylock
      wireplumber
      wl-clipboard
      niriPackages.xwayland-satellite-stable
    ];

    hm = {
      xdg.configFile = {
        "niri/config.kdl".source = ./niri/config.kdl;

        "mako/config".text = ''
          font=Sans 11
          background-color=#1e1e2eff
          text-color=#cdd6f4ff
          border-color=#89b4faff
          border-size=2
          border-radius=8
          default-timeout=5000
          anchor=top-right
        '';
      };

      programs.waybar = {
        enable = true;
        systemd.enable = false;
        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = ["niri/workspaces"];
          modules-center = ["clock"];
          modules-right = [
            "pulseaudio"
            "network"
            "battery"
            "tray"
          ];

          "niri/workspaces".format = "{icon}";
          clock.format = "{:%a %Y-%m-%d %H:%M}";
          pulseaudio = {
            format = "{volume}% {icon}";
            format-muted = "muted";
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          };
          network = {
            format-wifi = "{essid} {signalStrength}%";
            format-ethernet = "ethernet";
            format-disconnected = "offline";
          };
          battery = {
            format = "{capacity}%";
            format-charging = "{capacity}% charging";
          };
        };
      };

      systemd.user.services.niri-polkit-agent = {
        Unit = {
          Description = "PolicyKit authentication agent for Niri";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install.WantedBy = ["niri.service"];
      };
    };
  };
}
