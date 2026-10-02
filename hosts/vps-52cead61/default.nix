{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "vps-52cead61";

  # Network configuration
  networking = {
    useDHCP = lib.mkDefault true;
    interfaces.ens3 = {
      useDHCP = lib.mkDefault true;
      ipv6.addresses = [
        {
          address = "2607:5300:205:200::882f";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway6 = {
      address = "2607:5300:205:200::1";
      interface = "ens3";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [22];
      allowedUDPPorts = [];
    };
  };

  # Bootloader setup (hybrid UEFI + BIOS MBR for OVH VPS hypervisor)
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "/dev/sda";
  };

  # Primary user account per Dama Construction specification
  user = {
    name = "damacs";
    description = "Providence Salumu";
    email = "psalumu@damaconstruction.com";
    extraGroups = [
      "wheel"
    ];
  };

  modules.security.passwordlessSudo.enable = true;

  # OpenSSH server setup
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Authorized SSH public keys
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL30D3sXhSMM46UOQnTO24EIhspP9I1YuyXbGB5jCrsO psalumu@damaconstruction.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5Ai7Y1w6dQbhS/nUlFrjoe/Bugbdw6liqDxaJIszOF"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/WPI+COh3s4rDW6AAHmm2j4MKiR/GciHtsLItFTlv9 Providence.Salumu@smunix.com"
  ];

  users.users.damacs.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL30D3sXhSMM46UOQnTO24EIhspP9I1YuyXbGB5jCrsO psalumu@damaconstruction.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5Ai7Y1w6dQbhS/nUlFrjoe/Bugbdw6liqDxaJIszOF"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/WPI+COh3s4rDW6AAHmm2j4MKiR/GciHtsLItFTlv9 Providence.Salumu@smunix.com"
  ];

  # SOPS-Nix configuration using SSH host key for age decryption
  sops = {
    defaultSopsFile = "${inputs.secrets}/hosts/vps-52cead61/secrets.yaml";
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    secrets = {
      "initial_setup/status" = {};
    };
  };

  # Dynamic system MOTD banner using rust-motd
  modules.services.motd = {
    enable = true;
    networkInterface = "ens3";
    services = {};
  };

  # Basic system packages for remote server administration
  environment.systemPackages = with pkgs; [
    bottom
    btop
    curl
    git
    htop
    tmux
    vim
  ];

  system.stateVersion = "26.05";
}
