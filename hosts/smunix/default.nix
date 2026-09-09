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
    ai = {
      enable = true;
      client = "kimi";
    };

    networking.networkManager.enable = true;

    hardware = {
      pipewire.enable = true;
      printing = {
        enable = true;
        networkDiscovery.enable = true;
      };
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
      obsbot = {
        enable = true;
        usb.vendorId = "3564";
        video.deviceSymlink = "obsbot-tail2";
        audio = {
          enable = true;
          sourcePattern = "(obsbot|tail[ _-]?2|3564)";
          virtualSourceName = "obsbot_dji_mic";
          sampleRate = 48000;
          channels = 2;
          setDefault = true;
        };
        obs = {
          autoStart = true;
          collection = "Tail 2";
          profile = "Tail 2";
          scene = "Tail 2";
        };
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
    security = {
      fingerprint = {
        enable = true;
        enrollment.fingers = [
          "left-index-finger"
          "right-index-finger"
        ];
      };

      yubikey = {
        enable = true;
        origin = "pam://smunix";
        appId = "pam://smunix";
      };

      luksFido2 = {
        enable = true;
        devices = [
          "luks-cf3ef773-afb0-4a61-9c7c-ebb776b3d904"
          "luks-3de955a1-3d2d-46bc-9c4c-d2f92137a73a"
        ];
      };
    };

    vcs = {
      git.enable = true;
      jujutsu.enable = true;
    };

    desktop = {
      plasma = {
        enable = true;
        screenLock = {
          enable = true;
          timeoutMinutes = 10;
          lockOnResume = true;
          graceSeconds = 0;
        };
      };
      niri = {
        enable = true;
        screenLock = {
          enable = true;
          timeoutSeconds = 600;
          screenOffDelaySeconds = 60;
          lockOnSuspend = true;
        };
      };
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
      fonts.compact = {
        enable = true;
        reduction = 25;
      };
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
      obs = {
        enable = true;
        ndi.enable = true;
        virtualCamera = {
          enable = true;
          videoNr = 10;
        };
      };
      cli = {
        compress.enable = true;
        search.enable = true;
        system.enable = true;
        videos.enable = true;
      };
    };
  };

  hm.modules = {
    base.enable = true;
    packages.enable = true;
  };
}
