{pkgs, ...}: {
  imports = [./hardware.nix];

  user = {
    name = "smunix";
    description = "Providence Salumu";
    email = "Providence.Salumu@smunix.com";
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

    develop = {
      cc.enable = true;
      haskell.enable = true;
      python.enable = true;
      rust.enable = true;
    };

    shell = {
      default = "nushell";
      zellij.enable = true;
    };
    security.passwordlessSudo.enable = true;

    vcs = {
      git.enable = true;
      jujutsu.enable = true;
    };

    desktop = {
      plasma.enable = true;
      niri.enable = true;
      terminal.default = "wezterm";
      browsers.brave.enable = true;
      editors = {
        default = "helix";
        helix.enable = true;
        vim.enable = true;
        zed.enable = true;
      };
    };

    programs = {
      firefox.enable = true;
      waybar.enable = true;
    };
  };

  hm.modules = {
    base.enable = true;
    packages.enable = true;
  };
}
