{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.ai;
  clients = {
    antigravity = pkgs.google-antigravity-cli;
    kimi = pkgs.kimi-code;
  };
  selectedClients =
    if cfg.client != null
    then [cfg.client]
    else cfg.clients;
  kimiEnabled = lib.elem "kimi" selectedClients;

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
    enable = lib.mkEnableOption "AI coding clients";

    clients = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (lib.attrNames clients));
      default = ["kimi"];
      apply = lib.unique;
      example = [
        "kimi"
        "antigravity"
      ];
      description = "AI coding clients to install together.";
    };

    client = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (lib.attrNames clients));
      default = null;
      example = "kimi";
      description = "Deprecated compatibility option for selecting one AI client; use clients instead.";
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

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = selectedClients != [];
          message = "modules.ai.clients must select at least one AI coding client when modules.ai.enable is true.";
        }
      ];

      warnings = lib.optional (cfg.client != null) "modules.ai.client is deprecated; use modules.ai.clients instead.";

      user.packages = map (name: clients.${name}) selectedClients ++ lib.optional kimiEnabled pkgs.age;
    }

    (lib.mkIf kimiEnabled {
      hm.systemd.user.services.kimi-code-config = {
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
    })
  ]);
}
