{
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  hostSshPublicKey = builtins.getEnv "AYA_SSH_PUBLIC_KEY";
in {
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
    openssh.authorizedKeys.keys = lib.optional (hostSshPublicKey != "") hostSshPublicKey;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      AllowUsers = ["dev"];
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  environment.systemPackages = with pkgs; [
    aya-tool
    bpftools
    iproute2
    pahole
    tcpdump
  ];

  virtualisation = {
    memorySize = 4096;
    cores = 4;
    graphics = false;
    forwardPorts = [
      {
        from = "host";
        host = {
          address = "127.0.0.1";
          port = 2222;
        };
        guest.port = 22;
      }
    ];
    sharedDirectories.host = {
      source = ''"''${AYA_SHARED_DIRECTORY:?launch with: ebpf-vm --shared-directory PATH}"'';
      target = "/host";
    };
  };

  services.getty.autologinUser = "root";

  system.stateVersion = "26.05";
}
