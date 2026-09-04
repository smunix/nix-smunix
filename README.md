# nix-smunix

This repository defines the `smunix` NixOS system and its Home Manager profile as a modular flake. It uses [flake-parts](https://flake.parts/) to compose system-independent outputs and per-system packages and tooling. Its structure follows the main architectural conventions of the [`01-dratrion-nix`](https://github.com/smunix/snowflake/tree/01-dratrion-nix) branch of Snowflake: hosts are discovered from the filesystem, shared modules are imported recursively, and each host is a concise feature manifest rather than a monolithic configuration file.

## Repository structure

| Path | Purpose |
|---|---|
| `flake.nix` | Declares inputs and delegates output composition to flake-parts. |
| `parts/flake.nix` | Exposes hosts, overlays, reusable NixOS modules, and Home Manager modules. |
| `parts/per-system.nix` | Defines packages and formatters for every supported system. |
| `default.nix` | Applies configuration shared by every NixOS host and integrates Home Manager. |
| `lib/` | Contains filesystem module discovery and host-construction helpers. |
| `hosts/<name>/default.nix` | Declares host identity and enables reusable features. |
| `hosts/<name>/hardware.nix` | Stores generated and machine-specific hardware declarations. |
| `modules/nixos/` | Contains reusable NixOS feature modules. |
| `modules/home-manager/` | Contains reusable Home Manager feature modules. |
| `overlays/` | Contains one automatically exported overlay per file. |
| `pkgs/` | Contains custom packages exposed through the additions overlay. |
| `MODULES.md` | Provides a complete inventory of custom modules and extension points. |

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
    typst.enable = true;
    # quarto.enable = true;
  };

  shell = {
    default = "nushell";
    starship.enable = true;
    zellij.enable = true;
  };

  vcs = {
    git.enable = true;
    jujutsu.enable = true;
  };

  desktop = {
    plasma.enable = true;
    niri.enable = true;
    terminal = {
      default = "ghostty";
      ghostty.enable = true;
      wezterm.enable = true;
    };
    browsers.brave.enable = true;
    chats = {
      discord.enable = true;
      signal.enable = true;
    };
    fonts.compact.enable = true;
    viewers.tdf.enable = true;
    editors = {
      default = "helix";
      helix.enable = true;
      vim.enable = true;
      zed.enable = true;
    };
  };
};
```

Typst provides the Typst compiler, Tinymist language server, and Typstyle formatter. Quarto remains available as an opt-in publishing feature through `modules.develop.quarto.enable`.

Nushell and the terminal selector remain separate because Nushell is the user’s login shell while Ghostty and WezTerm are graphical terminal emulators. Ghostty is the selected default and both terminals explicitly start Nushell; WezTerm remains installed as an alternative. Starship supplies the Nushell prompt. The selected editor is exported as `EDITOR` and `VISUAL` through both the system and Home Manager session environments. Zellij remains available as a tmux alternative and opens Nushell panes with Helix as its scrollback editor. Git and Jujutsu are grouped under `modules.vcs`.

Home Manager’s official flake-parts module provides the canonical `homeModules` and `homeConfigurations` output interfaces. The repository also preserves `homeManagerModules` as a compatibility alias. At runtime, Home Manager remains integrated into the NixOS module graph; the shared `hm` alias points to `home-manager.users.<primary-user>`, while generic Home Manager features retain their own `modules` namespace:

```nix
hm.modules = {
  base.enable = true;
  packages.enable = true;
};
```

A new NixOS module can be added anywhere below `modules/nixos/` as a `.nix` file. It is imported recursively without requiring a central registration list. Home Manager modules follow the same convention below `modules/home-manager/`. Files and directories whose names begin with an underscore are ignored by discovery and can be used for private implementation helpers.

## Desktop sessions

Both Plasma and Niri are enabled as independent sessions in SDDM. At the login screen, use the session selector to choose **Plasma (Wayland)** or **Niri**, then sign in normally. SDDM remembers the most recently selected session.

The Niri session uses Noctalia as its complete desktop shell. Noctalia owns the rounded top bar, application launcher, clipboard history, notifications, lock screen, OSD, control center, session menu, wallpaper, weather, media controls, and desktop clock/weather/media widgets. The visual profile uses wallpaper-derived dark colors, Maple Mono NF CN, Papirus icons, a Bibata cursor, and the included café wallpaper. Ghostty is styled with a translucent dark palette and starts Nushell with Starship.

Normal application windows open maximized to Niri’s usable workspace area. Noctalia’s own settings window is exempt and remains floating. The persistent named workspaces route applications as follows:

| Shortcut | Workspace | Applications |
|---|---|---|
| `Super+1` | `shell` | WezTerm, Ghostty, XTerm |
| `Super+2` | `internet` | Firefox, Brave |
| `Super+3` | `viewers` | Okular, Evince, Xpdf; TDF runs inside the terminal |
| `Super+4` | `programming` | Zed (`zeditor`) |
| `Super+5` | `explorers` | Dolphin |
| `Super+6` | `chats` | Discord, Signal Desktop |
| `Super+7` | `dumpster` | Any normal application not matched by a more specific rule |

The Xpdf routing rule is included, but the pinned Xpdf 4.06 package is not installed because nixpkgs marks it insecure due to CVE-2023-26930. Okular and Evince remain installed as the default graphical PDF viewers. TDF is enabled independently as a terminal PDF viewer; run `tdf document.pdf` from Ghostty, WezTerm, or XTerm.

Unmatched normal applications default to `dumpster`; later application-specific rules override that fallback. Use `Super+Ctrl+1` through `Super+Ctrl+7` to move the focused column to the corresponding named workspace. Other desktop controls include `Super+Return` for Ghostty, `Super+D` or `Super+Space` for the launcher, `Super+S` for Control Center, `Super+E` for the session menu, `Super+Shift+V` for clipboard history, `Super+Shift+W` for wallpapers, `Super+Shift+,` for settings, `Super+Shift+D` for desktop-widget editing, `Ctrl+Alt+L` to lock, and `Super+Shift+E` to exit Niri. The complete key map is stored in `modules/nixos/desktop/niri/config.kdl`.

The compact-font feature reduces the configured Noctalia, GTK, Qt, KDE, X11, Ghostty, WezTerm, and Zed font baselines by 15%. Application-specific document or web-page zoom remains controlled by the application.

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

## Passwordless sudo

The `smunix` host enables `modules.security.passwordlessSudo`. This feature adds a `NOPASSWD` sudo rule only for the configured primary user, `smunix`; it does not relax the password requirement for every member of the `wheel` group. Since unrestricted passwordless sudo grants full administrator access, enable it only on a machine where that access model is intentional.
