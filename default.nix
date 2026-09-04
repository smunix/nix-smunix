{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib.modules) mkAliasOptionModule;
in {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      (mkAliasOptionModule ["hm"] [
        "home-manager"
        "users"
        config.user.name
      ])
    ]
    ++ inputs.self.lib.mapModulesRec' ./modules/nixos import;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs;};
    sharedModules = [
      (import ./modules/home-manager)
    ];
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      config.user.name
    ];
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "America/New_York";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  system = {
    stateVersion = "26.05";
    configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;
  };
}
