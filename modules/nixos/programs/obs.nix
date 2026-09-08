{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) escapeShellArgs mkEnableOption mkIf mkMerge mkOption optionalString types;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkAfter;
  cfg = config.modules.programs.obs;
  obsbotCfg = cfg.obsbotAutoStart;
  obsbotDevice = "/dev/${obsbotCfg.deviceSymlink}";
  obsbotProductMatch = optionalString (obsbotCfg.productId != null) ", ATTRS{idProduct}==\"${obsbotCfg.productId}\"";

  waitForObsbot = pkgs.writeShellScript "wait-for-obsbot-tail2" ''
    for _attempt in $(${pkgs.coreutils}/bin/seq 1 40); do
      [[ -e ${lib.escapeShellArg obsbotDevice} ]] && exit 0
      ${pkgs.coreutils}/bin/sleep 0.25
    done

    echo "Timed out waiting for ${obsbotDevice}" >&2
    exit 1
  '';

  obsbotCommand = escapeShellArgs [
    "${config.programs.obs-studio.finalPackage}/bin/obs"
    "--startvirtualcam"
    "--minimize-to-tray"
    "--disable-missing-files-check"
    "--collection"
    obsbotCfg.collection
    "--profile"
    obsbotCfg.profile
    "--scene"
    obsbotCfg.scene
  ];

  startObsbot = pkgs.writeShellScript "start-obsbot-tail2" ''
    ${optionalString obsbotCfg.notify ''
      ${pkgs.libnotify}/bin/notify-send \
        --app-name="OBSBOT" \
        --icon="camera-video" \
        "OBSBOT Tail 2 connected" \
        "Starting OBS Studio and /dev/video${toString cfg.virtualCamera.videoNr}."
    ''}

    exec ${obsbotCommand}
  '';
in {
  options.modules.programs.obs = {
    enable = mkEnableOption "OBS Studio for recording and live streaming";
    ndi.enable = mkEnableOption "NDI network audio and video support through the obs-ndi compatibility package";

    virtualCamera = {
      enable = mkEnableOption "the OBS virtual camera backed by v4l2loopback";
      videoNr = mkOption {
        type = types.ints.between 0 255;
        default = 10;
        description = "Video device number assigned to the OBS virtual camera.";
      };
    };

    obsbotAutoStart = {
      enable = mkEnableOption "automatic OBS and virtual-camera startup when the OBSBOT Tail 2 UVC interface appears";
      vendorId = mkOption {
        type = types.strMatching "^[0-9A-Fa-f]{4}$";
        default = "3564";
        description = "USB vendor ID used to match the Tail 2 parent device.";
      };
      productId = mkOption {
        type = types.nullOr (types.strMatching "^[0-9A-Fa-f]{4}$");
        default = null;
        description = "Optional Tail 2 UVC product ID used to narrow the udev rule.";
      };
      deviceSymlink = mkOption {
        type = types.strMatching "^[A-Za-z0-9._-]+$";
        default = "obsbot-tail2";
        description = "Stable device symlink created below /dev for the primary Tail 2 capture interface.";
      };
      collection = mkOption {
        type = types.str;
        default = "Tail 2";
        description = "Existing OBS scene collection selected during automatic startup.";
      };
      profile = mkOption {
        type = types.str;
        default = "Tail 2";
        description = "Existing OBS profile selected during automatic startup.";
      };
      scene = mkOption {
        type = types.str;
        default = "Tail 2";
        description = "Existing OBS scene selected during automatic startup.";
      };
      notify = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to show a desktop notification before OBS starts.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.ndi.enable || (pkgs.config.allowUnfree or false);
          message = "modules.programs.obs.ndi requires an unfree-enabled package set for the proprietary NDI SDK.";
        }
        {
          assertion = !obsbotCfg.enable || cfg.virtualCamera.enable;
          message = "modules.programs.obs.obsbotAutoStart requires modules.programs.obs.virtualCamera.enable.";
        }
      ];

      programs.obs-studio = {
        enable = true;
        plugins = optional cfg.ndi.enable pkgs.obs-studio-plugins.obs-ndi;
      };

      user = {
        packages = [pkgs.v4l-utils];
        extraGroups = mkAfter [
          "video"
          "render"
        ];
      };
    }

    (mkIf cfg.virtualCamera.enable {
      boot = {
        kernelModules = ["v4l2loopback"];
        extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
        extraModprobeConfig = ''
          options v4l2loopback devices=1 video_nr=${toString cfg.virtualCamera.videoNr} card_label="OBS Cam" exclusive_caps=1
        '';
      };
      security.polkit.enable = true;
    })

    (mkIf obsbotCfg.enable {
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", ATTR{index}=="0", ATTRS{idVendor}=="${obsbotCfg.vendorId}"${obsbotProductMatch}, ENV{ID_V4L_CAPABILITIES}=="*:capture:*", SYMLINK+="${obsbotCfg.deviceSymlink}", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="obsbot-tail2.service"
      '';

      hm.systemd.user.services.obsbot-tail2 = {
        Unit = {
          Description = "Start OBS for the OBSBOT Tail 2";
          After = [
            "graphical-session.target"
            "pipewire.service"
            "wireplumber.service"
          ];
          Wants = [
            "pipewire.service"
            "wireplumber.service"
          ];
          PartOf = ["graphical-session.target"];
          ConditionPathExists = obsbotDevice;
        };

        Service = {
          Type = "simple";
          ExecStartPre = waitForObsbot;
          ExecStart = startObsbot;
          Restart = "on-failure";
          RestartSec = 3;
        };

        Install.WantedBy = ["graphical-session.target"];
      };
    })
  ]);
}
