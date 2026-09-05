{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.nvidia;
in {
  options.modules.hardware.nvidia = {
    enable = lib.mkEnableOption "NVIDIA PRIME offload graphics";

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
    ];

    hardware = {
      graphics.enable = true;
      nvidia = {
        modesetting.enable = true;
        powerManagement = {
          enable = true;
          finegrained = true;
        };
        open = true;
        nvidiaSettings = true;
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          inherit (cfg) intelBusId nvidiaBusId;
        };
      };
    };

    services.xserver.videoDrivers = ["nvidia"];
  };
}
