{
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = ["${modulesPath}/virtualisation/qemu-vm.nix"];

  networking.hostName = "aya-ebpf-lab";

  boot.kernelPatches = [
    {
      name = "aya-ebpf";
      patch = null;
      extraConfig = ''
        BPF_SYSCALL y
        BPF_JIT y
        BPF_JIT_ALWAYS_ON y
        DEBUG_INFO_BTF y
        BPF_LSM y
        CGROUPS y
        NAMESPACES y
        SECCOMP y
        SECCOMP_FILTER y
        AUDIT y
      '';
    }
  ];

  security.lsm = lib.mkForce [
    "landlock"
    "lockdown"
    "yama"
    "integrity"
    "bpf"
  ];

  users.users.dev = {
    isNormalUser = true;
    uid = 1001;
    initialPassword = "dev";
    extraGroups = ["wheel"];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  environment.systemPackages = with pkgs; [
    bpftools
    iproute2
    pahole
    tcpdump
  ];

  virtualisation = {
    memorySize = 4096;
    cores = 4;
    graphics = false;
    sharedDirectories.host = {
      source = ''"''${AYA_SHARED_DIRECTORY:?launch with: ebpf-vm --shared-directory PATH}"'';
      target = "/host";
    };
  };

  services.getty.autologinUser = "root";

  system.stateVersion = "26.05";
}
