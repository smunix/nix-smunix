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

  networking.hostName = "vps-73025e99";

  # Network configuration
  networking = {
    useDHCP = lib.mkDefault true;
    interfaces.ens3 = {
      useDHCP = lib.mkDefault true;
      ipv6.addresses = [{
        address = "2607:5300:205:200::bc53";
        prefixLength = 64;
      }];
    };
    defaultGateway6 = {
      address = "2607:5300:205:200::1";
      interface = "ens3";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443];
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

  # User account configuration
  user = {
    name = "smunix";
    description = "Providence Salumu";
    email = "Providence.Salumu@smunix.com";
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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/WPI+COh3s4rDW6AAHmm2j4MKiR/GciHtsLItFTlv9 Providence.Salumu@smunix.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5Ai7Y1w6dQbhS/nUlFrjoe/Bugbdw6liqDxaJIszOF"
  ];

  users.users.smunix.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/WPI+COh3s4rDW6AAHmm2j4MKiR/GciHtsLItFTlv9 Providence.Salumu@smunix.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5Ai7Y1w6dQbhS/nUlFrjoe/Bugbdw6liqDxaJIszOF"
  ];

  # SOPS-Nix configuration using SSH host key for age decryption
  sops = {
    defaultSopsFile = "${inputs.secrets}/hosts/vps-73025e99/secrets.yaml";
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    secrets = {
      "initial_setup/status" = {};
      "gitlab/deploy_key" = {
        owner = "smunix";
        mode = "0400";
        path = "/home/smunix/.ssh/id_gitlab_deploy";
      };
    };
  };

  # SSH client configuration for GitLab
  programs.ssh.extraConfig = ''
    Host gitlab.com
      HostName gitlab.com
      User git
      IdentityFile /home/smunix/.ssh/id_gitlab_deploy
      IdentitiesOnly yes
  '';

  # Hodari Accounting service (Dioxus server on 127.0.0.1:8080)
  modules.services.hodari-accounting.enable = true;

  # Caddy reverse proxy for HTTPS termination (port 80/443 -> 8080)
  services.caddy = {
    enable = true;
    virtualHosts."accounting.hodari.ca" = {
      extraConfig = ''
        encode zstd gzip

        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "SAMEORIGIN"
        }

        reverse_proxy 127.0.0.1:8080
      '';
    };

    virtualHosts."vps-73025e99.vps.ovh.ca" = {
      extraConfig = ''
        redir https://accounting.hodari.ca{uri} permanent
      '';
    };
  };

  # Basic system packages for remote server administration
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    tmux
    vim
  ];

  system.stateVersion = "26.05";
}
