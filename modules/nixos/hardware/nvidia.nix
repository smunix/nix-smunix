{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.nvidia;
in {
  options.modules.hardware.nvidia = {
    enable = lib.mkEnableOption "NVIDIA hybrid graphics";

    powerManagement = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to preserve NVIDIA video memory across suspend and resume.";
      };

      finegrained = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to power down the NVIDIA GPU dynamically while PRIME offload is idle.";
      };
    };

    prime = {
      sync.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to use PRIME synchronization with the NVIDIA GPU driving the display session.";
      };

      offload = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to use PRIME render offload.";
        };

        enableOffloadCmd = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to install the nvidia-offload command for PRIME render offload.";
        };
      };
    };

    intelBusId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Host-specific PCI bus ID of the Intel integrated GPU.";
      example = "PCI:0:2:0";
    };

    nvidiaBusId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Host-specific PCI bus ID of the NVIDIA discrete GPU.";
      example = "PCI:1:0:0";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.intelBusId != "";
        message = "NVIDIA PRIME requires the host-specific Intel PCI bus ID.";
      }
      {
        assertion = cfg.nvidiaBusId != "";
        message = "NVIDIA PRIME requires the host-specific NVIDIA PCI bus ID.";
      }
      {
        assertion = !(cfg.prime.sync.enable && cfg.prime.offload.enable);
        message = "NVIDIA PRIME sync and offload modes cannot be enabled at the same time.";
      }
      {
        assertion = !cfg.prime.offload.enableOffloadCmd || cfg.prime.offload.enable;
        message = "The NVIDIA offload command requires PRIME offload to be enabled.";
      }
      {
        assertion = !cfg.powerManagement.finegrained || cfg.powerManagement.enable;
        message = "NVIDIA fine-grained power management requires NVIDIA power management.";
      }
      {
        assertion = !cfg.powerManagement.finegrained || cfg.prime.offload.enable;
        message = "NVIDIA fine-grained power management requires PRIME offload mode.";
      }
    ];

    hardware = {
      graphics.enable = true;
      nvidia = {
        modesetting.enable = true;
        inherit (cfg) powerManagement;
        open = true;
        nvidiaSettings = true;
        prime = {
          inherit (cfg.prime) sync offload;
          inherit (cfg) intelBusId nvidiaBusId;
        };
      };
    };

    services.xserver.videoDrivers = ["nvidia"];
  };
}
