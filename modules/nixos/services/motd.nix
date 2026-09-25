{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.motd;

  headerScript = pkgs.writeShellScript "motd-header" ''
    echo "Welcome to NixOS $(nixos-version) ($(uname -srm))"
    echo " * NixOS Manual:      https://nixos.org/manual/nixos/stable/"
    readlink /nix/var/nix/profiles/system 2>/dev/null | awk -F'-' '{print " * System Generation: " $2}'
  '';

  netScript = pkgs.writeShellScript "motd-network" ''
    iface="${
      if cfg.networkInterface != null
      then cfg.networkInterface
      else ""
    }"
    if [ -n "$iface" ]; then
      ipv4="$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)"
      ipv6="$(ip -6 addr show "$iface" scope global 2>/dev/null | awk '/inet6 / {print $2}' | cut -d/ -f1 | head -n1)"
      if [ -n "$ipv4" ] && [ -n "$ipv6" ]; then
        echo "IPv4 ($iface): $ipv4  |  IPv6: $ipv6"
      elif [ -n "$ipv4" ]; then
        echo "IPv4 ($iface): $ipv4"
      elif [ -n "$ipv6" ]; then
        echo "IPv6 ($iface): $ipv6"
      fi
    fi
  '';

  serviceEntries = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (displayName: unit: ''
      service display-name="${displayName}" unit="${unit}"
    '')
    cfg.services
  );

  serviceBlock = lib.optionalString (cfg.services != {}) ''
    service-status {
      ${serviceEntries}
    }
  '';

  fsEntries = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: mount: ''
      filesystem name="${name}" mount-point="${mount}"
    '')
    cfg.filesystems
  );

  fsBlock = lib.optionalString (cfg.filesystems != {}) ''
    filesystems {
      ${fsEntries}
    }
  '';

  motdConfig = pkgs.writeText "rust-motd-config.kdl" ''
    global {
      version "1.0"
    }
    components {
      command "${headerScript}"
      uptime prefix="Uptime"
      load-avg format="Load (1, 5, 15 min.): {one:.02}, {five:.02}, {fifteen:.02}"
      ${fsBlock}
      memory swap-pos="beside"
      ${lib.optionalString (cfg.networkInterface != null) ''
      command "${netScript}"
    ''}
      ${serviceBlock}
    }
  '';

  bashCondition =
    if cfg.sshOnly
    then ''[ -n "$SSH_CONNECTION" ] && [ -t 1 ] && [ -z "''${_MOTD_SHOWN:-}" ]''
    else ''[ -t 1 ] && [ -z "''${_MOTD_SHOWN:-}" ]'';

  nuCondition =
    if cfg.sshOnly
    then "($env.SSH_CONNECTION? != null) and ($env._MOTD_SHOWN? == null)"
    else "($nu.is-interactive) and ($env._MOTD_SHOWN? == null)";
in {
  options.modules.services.motd = {
    enable = lib.mkEnableOption "dynamic system MOTD banner using rust-motd";

    sshOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to only display the banner on remote SSH logins (set false for local terminals).";
    };

    networkInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Primary network interface to display IPv4 and IPv6 addresses for.";
    };

    filesystems = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        "root" = "/";
      };
      description = "Filesystems to monitor (name -> mount point).";
    };

    services = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        "Caddy" = "caddy";
        "Hodari Accounting" = "hodari-accounting";
      };
      description = "Mapping of display names to systemd unit names.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.rust-motd];

    environment.interactiveShellInit = ''
      if ${bashCondition}; then
        export _MOTD_SHOWN=1
        ${pkgs.rust-motd}/bin/rust-motd ${motdConfig}
      fi
    '';

    hm.programs.nushell.extraConfig = lib.mkIf (config.modules.shell.default or null == "nushell") ''
      if ${nuCondition} {
        $env._MOTD_SHOWN = "1"
        ^${pkgs.rust-motd}/bin/rust-motd ${motdConfig}
      }
    '';
  };
}
