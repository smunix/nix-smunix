{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.vcs.forges;
  ghCfg = config.modules.vcs.gh;
  glabCfg = config.modules.vcs.glab;
in {
  options.modules.vcs = {
    forges = {
      enable = lib.mkEnableOption "Git forge CLI tools (GitHub gh and GitLab glab)";
      gh = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GitHub CLI (gh).";
        };
      };
      glab = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GitLab CLI (glab).";
        };
      };
    };

    gh.enable = lib.mkEnableOption "GitHub CLI (gh)";
    glab.enable = lib.mkEnableOption "GitLab CLI (glab)";
  };

  config = lib.mkMerge [
    (lib.mkIf ((cfg.enable && cfg.gh.enable) || ghCfg.enable) {
      hm.programs.gh = {
        enable = true;
        package = pkgs.gh;
        settings = {
          git_protocol = "ssh";
          prompt = "enabled";
        };
      };
    })

    (lib.mkIf ((cfg.enable && cfg.glab.enable) || glabCfg.enable) {
      user.packages = [pkgs.glab];
    })
  ];
}
