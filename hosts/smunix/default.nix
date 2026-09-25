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
      clients = [
        "kimi"
        "antigravity"
      ];
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
        powerManagement = {
          enable = false;
          finegrained = false;
        };
        prime = {
          sync.enable = true;
          offload = {
            enable = false;
            enableOffloadCmd = false;
          };
        };
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
      aya.enable = true;
      cc.enable = true;
      dioxus = {
        enable = true;
        desktop = {
          enable = true;
          libclangPackage = pkgs.llvmPackages.libclang;
        };
        developmentServer = {
          enable = true;
          address = "127.0.0.1";
          port = 8080;
          openFirewall = false;
          caddy = {
            enable = true;
            networkInterface = "wlp0s20f3";
            tlsMode = "internal";
            openFirewall = true;
          };
        };
        web = {
          enable = true;
          wasmBindgenCliPackage = pkgs.wasm-bindgen-cli_0_2_128;
        };
        android = {
          enable = true;
          platformVersions = [
            "34"
            "35"
          ];
          buildToolsVersions = [
            "34.0.0"
            "35.0.0"
          ];
          ndkVersion = "27.2.12479018";
          cmakeVersion = "3.22.1";
          includeEmulator = true;
          includeSystemImage = true;
          rustTargets = [
            "aarch64-linux-android"
            "armv7-linux-androideabi"
            "i686-linux-android"
            "x86_64-linux-android"
          ];
        };
      };
      haskell.enable = true;
      python.enable = true;
      rust = {
        enable = true;
        channel = "stable";
        version = "1.98.1";
      };
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
      forges.enable = true;
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
        packageChannel = "unstable";
        monitorLayout = {
          enable = true;
          primaryOutput = "external";
          external = {
            connector = "DP-5";
            mode = "2560x1440@59.91";
            scale = 1;
            transform = "90";
            position = {
              x = 0;
              y = 0;
            };
            fullWidthColumns = true;
          };
          internal = {
            connector = "eDP-1";
            mode = "3840x2400@59.99";
            scale = 2;
            transform = "normal";
            position = {
              x = 1440;
              y = 0;
            };
          };
        };
        gammastep = {
          enable = true;
          locationProvider = "geoclue2";
          fallbackToManual = true;
          latitude = 45.529999;
          longitude = -73.930000;
          locationTimeoutSeconds = 20;
          dayTemperature = 6500;
          nightTemperature = 3500;
        };
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
      socials = {
        zoom.enable = true;
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
      bottles.enable = true;
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

    ide = {
      enable = true;
      ides = [
        "antigravity"
        "zed"
      ];
    };

    services.motd = {
      enable = true;
      sshOnly = false;
      networkInterface = "wlp0s20f3";
      services = {
        "NetworkManager" = "NetworkManager";
        "CUPS" = "cups";
        "TLP" = "tlp";
        "Bluetooth" = "bluetooth";
      };
    };
  };

  hm.modules = {
    base.enable = true;
    packages.enable = true;
  };
}
