# This file was generated from nixos-generate-config output.
# Keep machine-specific filesystems, encryption, and hardware declarations here.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "vmd"
        "nvme"
        "uas"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [];
      luks.devices = {
        "luks-cf3ef773-afb0-4a61-9c7c-ebb776b3d904".device = "/dev/disk/by-uuid/cf3ef773-afb0-4a61-9c7c-ebb776b3d904";
        "luks-3de955a1-3d2d-46bc-9c4c-d2f92137a73a".device = "/dev/disk/by-uuid/3de955a1-3d2d-46bc-9c4c-d2f92137a73a";
      };
    };

    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/luks-cf3ef773-afb0-4a61-9c7c-ebb776b3d904";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/FE0D-66FA";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    {device = "/dev/mapper/luks-3de955a1-3d2d-46bc-9c4c-d2f92137a73a";}
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
