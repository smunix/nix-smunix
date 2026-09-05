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
      power = {
        backend = "tlp";
        lid.enable = true;
        tlp = {
          startChargeThreshold = 75;
          stopChargeThreshold = 80;
        };
      };
      nvidia = {
        enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    develop = {
      cc.enable = true;
      haskell.enable = true;
      python.enable = true;
      rust.enable = true;
      typst.enable = true;
    };

    shell = {
      default = "nushell";
      starship.enable = true;
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
      terminal = {
        default = "ghostty";
        ghostty.enable = true;
        wezterm.enable = true;
      };
      browsers.brave.enable = true;
      chats = {
        discord.enable = true;
        signal.enable = true;
      };
      fonts.compact.enable = true;
      viewers = {
        mpv.enable = true;
        tdf.enable = true;
        zathura.enable = true;
      };
      editors = {
        default = "helix";
        helix.enable = true;
        vim.enable = true;
        zed.enable = true;
      };
    };

    programs = {
      firefox.enable = true;
      cli = {
        search.enable = true;
        system.enable = true;
      };
    };
  };

  hm.modules = {
    base.enable = true;
    packages.enable = true;
  };
}
