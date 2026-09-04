# nix-smunix

This repository defines the `smunix` NixOS system and its Home Manager profile as a modular flake. Its structure follows the main architectural conventions of the [`01-dratrion-nix`](https://github.com/smunix/snowflake/tree/01-dratrion-nix) branch of Snowflake: hosts are discovered from the filesystem, shared modules are imported recursively, and each host is a concise feature manifest rather than a monolithic configuration file.

## Repository structure

| Path | Purpose |
|---|---|
| `flake.nix` | Exposes hosts, modules, overlays, packages, and formatters. |
| `default.nix` | Applies configuration shared by every NixOS host and integrates Home Manager. |
| `lib/` | Contains filesystem module discovery and host-construction helpers. |
| `hosts/<name>/default.nix` | Declares host identity and enables reusable features. |
| `hosts/<name>/hardware.nix` | Stores generated and machine-specific hardware declarations. |
| `modules/nixos/` | Contains reusable NixOS feature modules. |
| `modules/home-manager/` | Contains reusable Home Manager feature modules. |
| `overlays/` | Contains one automatically exported overlay per file. |
| `pkgs/` | Contains custom packages exposed through the additions overlay. |

## Module conventions

Each NixOS feature owns an option below the `modules` namespace. The `smunix` host enables features without repeating their implementation:

```nix
modules = {
  networking.networkManager.enable = true;
  hardware.pipewire.enable = true;

  develop = {
    cc.enable = true;
    haskell.enable = true;
    python.enable = true;
    rust.enable = true;
  };

  shell.default = "nushell";

  vcs = {
    git.enable = true;
    jujutsu.enable = true;
  };

  desktop = {
    plasma.enable = true;
    terminal.default = "wezterm";
    browsers.brave.enable = true;
    editors = {
      default = "helix";
      helix.enable = true;
      vim.enable = true;
      zed.enable = true;
    };
  };
};
```

Nushell and WezTerm have separate selectors because Nushell is the user’s login shell while WezTerm is the graphical terminal emulator. Git and Jujutsu are grouped under `modules.vcs`, and editors can be installed independently while one editor is selected as the command-line default.

Home Manager is integrated into the NixOS module graph. The shared `hm` alias points to `home-manager.users.<primary-user>`, while generic Home Manager features retain their own `modules` namespace:

```nix
hm.modules = {
  base.enable = true;
  packages.enable = true;
};
```

A new NixOS module can be added anywhere below `modules/nixos/` as a `.nix` file. It is imported recursively without requiring a central registration list. Home Manager modules follow the same convention below `modules/home-manager/`. Files and directories whose names begin with an underscore are ignored by discovery and can be used for private implementation helpers.

## Common commands

Format and validate the flake before rebuilding:

```sh
nix fmt
nix flake check
nix eval .#nixosConfigurations.smunix.config.system.build.toplevel.drvPath
```

Build or activate the host with:

```sh
sudo nixos-rebuild build --flake .#smunix
sudo nixos-rebuild switch --flake .#smunix
```

The host’s filesystem, encryption, swap, and CPU declarations remain isolated in `hosts/smunix/hardware.nix`. Keep those values aligned with the machine’s generated hardware configuration.
