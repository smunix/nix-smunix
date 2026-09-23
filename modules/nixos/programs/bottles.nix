{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.programs.bottles;
in {
  options.modules.programs.bottles = {
    enable = mkEnableOption "Bottles Windows environment manager via Flatpak";
  };

  config = mkIf cfg.enable {
    services.flatpak.enable = true;

    xdg.portal.enable = lib.mkDefault true;

    systemd.services.flatpak-bottles-setup = {
      description = "Ensure Flathub remote and Bottles Flatpak are installed";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = [
        pkgs.flatpak
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

        if ! flatpak info com.usebottles.bottles >/dev/null 2>&1; then
          flatpak install --noninteractive --system -y flathub com.usebottles.bottles || true
        fi

        flatpak override --system --filesystem=host com.usebottles.bottles || true
      '';
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "bottles" ''
        exec ${pkgs.flatpak}/bin/flatpak run com.usebottles.bottles "$@"
      '')
      (pkgs.writeShellScriptBin "bottles-cli" ''
        exec ${pkgs.flatpak}/bin/flatpak run --command=bottles-cli com.usebottles.bottles "$@"
      '')
    ];
  };
}
