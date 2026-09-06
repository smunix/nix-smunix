{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.ai;
  clients = {
    kimi = pkgs.kimi-code;
  };

  installKimiConfig = pkgs.writeShellScript "install-kimi-code-config" ''
    set -eu
    umask 077

    destination=${lib.escapeShellArg "${config.user.home}/.kimi-code/config.toml"}
    destinationDirectory="$(${pkgs.coreutils}/bin/dirname "$destination")"
    encryptedConfig=${lib.escapeShellArg (toString cfg.kimi.encryptedConfig)}

    ${pkgs.coreutils}/bin/install -d -m 0700 "$destinationDirectory"
    temporaryFile="$(${pkgs.coreutils}/bin/mktemp "$destinationDirectory/.config.toml.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$temporaryFile"' EXIT

    decrypted=false
    for identity in ${lib.escapeShellArgs cfg.kimi.identityPaths}; do
      if [ -r "$identity" ] && ${pkgs.age}/bin/age --decrypt --identity "$identity" "$encryptedConfig" > "$temporaryFile"; then
        decrypted=true
        break
      fi
      : > "$temporaryFile"
    done

    if [ "$decrypted" != true ]; then
      echo "Unable to decrypt the Kimi Code configuration with any configured SSH identity." >&2
      exit 1
    fi

    emptyApiKeyCount="$(${pkgs.gnugrep}/bin/grep -Ec '^[[:space:]]*api_key[[:space:]]*=[[:space:]]*""[[:space:]]*$' "$temporaryFile" || true)"

    if ! ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*default_model[[:space:]]*=[[:space:]]*".+"[[:space:]]*$' "$temporaryFile" \
      || [ "$emptyApiKeyCount" -ne 3 ] \
      || ! ${pkgs.gawk}/bin/awk '
        /^[[:space:]]*key[[:space:]]*=[[:space:]]*".+"[[:space:]]*$/ {
          value = $0
          sub(/^[^"]*"/, "", value)
          sub(/"[[:space:]]*$/, "", value)
          if (count == 0) {
            first = value
          } else if (value != first) {
            mismatch = 1
          }
          count++
        }
        END {
          exit !(count == 3 && mismatch == 0)
        }
      ' "$temporaryFile"; then
      echo "The decrypted Kimi Code configuration must use three matching non-empty key fields and three empty api_key fields." >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/chmod 0600 "$temporaryFile"
    ${pkgs.coreutils}/bin/mv -f "$temporaryFile" "$destination"
    trap - EXIT
  '';
in {
  options.modules.ai = {
    enable = lib.mkEnableOption "an AI coding client";

    client = lib.mkOption {
      type = lib.types.enum ["kimi"];
      default = "kimi";
      example = "kimi";
      description = "AI coding client to install. Additional clients can be added to the selector later.";
    };

    kimi = {
      encryptedConfig = lib.mkOption {
        type = lib.types.path;
        default = inputs.secrets + "/hosts/${config.networking.hostName}/apps/kimi-code/config.toml.age";
        description = "Age-encrypted complete Kimi Code TOML configuration from the private secrets input.";
      };

      identityPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "${config.user.home}/.ssh/id_ed25519"
          "${config.user.home}/.ssh/id_ed25519_sk"
          "${config.user.home}/.ssh/id_rsa"
        ];
        description = "SSH private-key paths tried in order when decrypting the Kimi Code configuration.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    user.packages = [
      clients.${cfg.client}
      pkgs.age
    ];

    hm.systemd.user.services.kimi-code-config = lib.mkIf (cfg.client == "kimi") {
      Unit = {
        Description = "Install the decrypted Kimi Code configuration";
        Documentation = "man:age(1)";
      };

      Service = {
        Type = "oneshot";
        ExecStart = installKimiConfig;
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
