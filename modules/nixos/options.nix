{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (lib.modules) mkDefault;
  cfg = config.user;
in {
  options.user = {
    name = mkOption {
      type = types.str;
      default = "smunix";
      description = "Primary user name for this host.";
    };

    description = mkOption {
      type = types.str;
      default = "";
      description = "Human-readable description for the primary user.";
    };

    home = mkOption {
      type = types.str;
      default = "/home/${cfg.name}";
      description = "Home directory of the primary user.";
    };

    extraGroups = mkOption {
      type = types.listOf types.str;
      default = ["wheel"];
      description = "Supplementary groups assigned to the primary user.";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "System-level packages installed for the primary user.";
    };
  };

  config = {
    users.users.${cfg.name} = {
      inherit (cfg) description extraGroups packages;
      isNormalUser = true;
      inherit (cfg) home;
    };

    hm.home = {
      username = mkDefault cfg.name;
      homeDirectory = mkDefault cfg.home;
      stateVersion = mkDefault config.system.stateVersion;
    };
  };
}
