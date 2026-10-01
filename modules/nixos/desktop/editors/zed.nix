{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.editors.zed;

  installZedGeminiKey = pkgs.writeShellScript "install-zed-gemini-key" ''
    set -eu
    umask 077

    runtimeDir="/run/user/$(${pkgs.coreutils}/bin/id -u)/zed"
    destination="$runtimeDir/gemini_api_key"
    ${pkgs.coreutils}/bin/install -d -m 0700 "$runtimeDir"

    encryptedKey=${lib.escapeShellArg (toString cfg.gemini.encryptedApiKey)}

    decrypted=false
    temporaryFile="$(${pkgs.coreutils}/bin/mktemp "$runtimeDir/.key.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$temporaryFile"' EXIT

    for identity in ${lib.escapeShellArgs cfg.gemini.identityPaths}; do
      if [ -r "$identity" ] && ${pkgs.age}/bin/age --decrypt --identity "$identity" "$encryptedKey" > "$temporaryFile" 2>/dev/null; then
        decrypted=true
        break
      fi
      : > "$temporaryFile"
    done

    if [ "$decrypted" = true ]; then
      ${pkgs.coreutils}/bin/chmod 0600 "$temporaryFile"
      ${pkgs.coreutils}/bin/mv -f "$temporaryFile" "$destination"
      key="$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$destination")"
      if [ -n "$key" ]; then
        ${pkgs.systemd}/bin/systemctl --user set-environment GEMINI_API_KEY="$key"
        ${pkgs.systemd}/bin/systemctl --user set-environment GOOGLE_AI_API_KEY="$key"
      fi
    else
      echo "Warning: Unable to decrypt Zed Gemini API key with any configured identity." >&2
    fi
    trap - EXIT
  '';

  wrappedZedEditor = pkgs.symlinkJoin {
    name = "zed-editor-wrapped";
    paths = [pkgs.zed-editor];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/zeditor \
        --run '
          if [ -z "''${GEMINI_API_KEY:-}" ]; then
            keyFile="/run/user/$(${pkgs.coreutils}/bin/id -u)/zed/gemini_api_key"
            if [ -r "$keyFile" ]; then
              export GEMINI_API_KEY="$(${pkgs.coreutils}/bin/tr -d "\r\n" < "$keyFile")"
              export GOOGLE_AI_API_KEY="$GEMINI_API_KEY"
            elif [ -n ${lib.escapeShellArg (toString cfg.gemini.encryptedApiKey)} ] && [ -f ${lib.escapeShellArg (toString cfg.gemini.encryptedApiKey)} ]; then
              for identity in ${lib.escapeShellArgs cfg.gemini.identityPaths}; do
                if [ -r "$identity" ]; then
                  key="$(${pkgs.age}/bin/age --decrypt --identity "$identity" ${lib.escapeShellArg (toString cfg.gemini.encryptedApiKey)} 2>/dev/null | ${pkgs.coreutils}/bin/tr -d "\r\n" || true)"
                  if [ -n "$key" ]; then
                    export GEMINI_API_KEY="$key"
                    export GOOGLE_AI_API_KEY="$key"
                    break
                  fi
                fi
              done
            fi
          fi
        '
    '';
  };
in {
  options.modules.desktop.editors.zed = {
    enable = lib.mkEnableOption "Zed editor";

    package = lib.mkOption {
      type = lib.types.package;
      default =
        if cfg.gemini.enable && cfg.gemini.encryptedApiKey != null
        then wrappedZedEditor
        else pkgs.zed-editor;
      description = "Zed editor package to install.";
    };

    gemini = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Gemini AI model integration in Zed.";
      };

      defaultModel = lib.mkOption {
        type = lib.types.str;
        default = "gemini-3.8-flash-high";
        description = "Default Gemini model for Zed assistant and agent.";
      };

      encryptedApiKey = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = let
          secretPath = inputs.secrets + "/hosts/${config.networking.hostName}/apps/zed/gemini_api_key.age";
        in
          if inputs ? secrets && builtins.pathExists secretPath
          then secretPath
          else null;
        description = "Path to the age-encrypted Gemini API key file from nix-secrets.";
      };

      identityPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "${config.user.home}/.ssh/id_ed25519"
          "${config.user.home}/.ssh/id_ed25519_sk"
          "${config.user.home}/.ssh/id_rsa"
        ];
        description = "SSH private-key paths tried in order when decrypting the Gemini API key.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      hm.programs.zed-editor = {
        enable = true;
        package = cfg.package;
        extensions = ["nix"];
        userSettings = {
          base_keymap = "VSCode";
          vim_mode = true;
          ui_font_size = 16.0 * config.modules.desktop.fonts.compact.factor;
          buffer_font_size = 16.0 * config.modules.desktop.fonts.compact.factor;
          assistant = {
            default_model = {
              provider = "google";
              model = cfg.gemini.defaultModel;
            };
            version = "2";
          };
          agent = {
            default_model = {
              provider = "google";
              model = cfg.gemini.defaultModel;
            };
          };
          language_models = {
            google = {
              available_models = [
                {
                  name = cfg.gemini.defaultModel;
                  display_name = "Gemini 3.8 Flash High";
                  max_tokens = 1000000;
                }
              ];
            };
          };
        };
      };
    }

    (lib.mkIf (cfg.gemini.enable && cfg.gemini.encryptedApiKey != null) {
      hm.systemd.user.services.zed-gemini-key = {
        Unit = {
          Description = "Decrypt and export Gemini API key for Zed editor";
          Documentation = "man:age(1)";
        };

        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = installZedGeminiKey;
        };

        Install.WantedBy = [
          "graphical-session.target"
          "default.target"
        ];
      };
    })
  ]);
}
