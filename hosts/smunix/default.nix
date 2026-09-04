{pkgs, ...}: {
  imports = [./hardware.nix];

  user = {
    name = "smunix";
    description = "Providence Salumu";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = [pkgs.kdePackages.kate];
  };

  modules = {
    networking.networkManager.enable = true;

    hardware = {
      pipewire.enable = true;
      printing.enable = true;
    };

    desktop = {
      plasma.enable = true;
      niri.enable = true;
    };

    programs = {
      firefox.enable = true;
      waybar.enable = true;
    };
  };

  hm.modules = {
    base.enable = true;
    packages.enable = true;
    programs.git.enable = true;
  };
}
