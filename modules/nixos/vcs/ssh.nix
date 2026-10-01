{
  config,
  lib,
  ...
}: let
  cfg = config.modules.vcs.ssh;
in {
  options.modules.vcs.ssh = {
    enable = lib.mkEnableOption "SSH client configuration for VCS and development";

    workKeyPath = lib.mkOption {
      type = lib.types.str;
      default = "~/.ssh/id_ed25519_dama";
      description = "Path to work SSH private key for Dama Construction.";
    };

    personalKeyPath = lib.mkOption {
      type = lib.types.str;
      default = "~/.ssh/id_ed25519";
      description = "Path to personal SSH private key.";
    };
  };

  config = lib.mkIf cfg.enable {
    hm.programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "vps-73025e99.vps.ovh.ca" = {
          HostName = "148.113.244.62";
          User = "smunix";
          IdentityFile = cfg.personalKeyPath;
        };
        "github.com-dama" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = cfg.workKeyPath;
          IdentitiesOnly = "yes";
        };
        "github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = cfg.personalKeyPath;
          IdentitiesOnly = "yes";
        };
      };
    };
  };
}
