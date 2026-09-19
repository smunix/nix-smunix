{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.ide;
  ides = {
    antigravity = pkgs.google-antigravity-ide;
    zed = pkgs.zed-editor;
  };
  selectedIdes =
    if cfg.ide != null
    then [cfg.ide]
    else cfg.ides;
in {
  options.modules.ide = {
    enable = lib.mkEnableOption "full GUI IDEs";

    ides = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (lib.attrNames ides));
      default = [];
      apply = lib.unique;
      example = [
        "antigravity"
        "zed"
      ];
      description = "Full GUI IDEs to install.";
    };

    # Deprecated single-selection shim kept for forward-compat.
    ide = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (lib.attrNames ides));
      default = null;
      example = "zed";
      description = "Deprecated single-IDE selector; use ides instead.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = selectedIdes != [];
          message = "modules.ide.ides must select at least one IDE when modules.ide.enable is true.";
        }
      ];

      warnings = lib.optional (cfg.ide != null) "modules.ide.ide is deprecated; use modules.ide.ides instead.";

      user.packages = map (name: ides.${name}) selectedIdes;
    }
  ]);
}
