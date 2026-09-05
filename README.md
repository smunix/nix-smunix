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
  hardware = {
    pipewire.enable = true;
    power = {
      backend = "tlp";
      lid.enable = true;
      tlp = {
        startChargeThreshold = 75;
        stopChargeThreshold = 80;
      };
    };
    nvidia = {
      enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

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

  security = {
    yubikey = {
      enable = true;
      origin = "pam://smunix";
      appId = "pam://smunix";
    };

    luksFido2 = {
      enable = true;
      devices = [
        "luks-cf3ef773-afb0-4a61-9c7c-ebb776b3d904"
        "luks-3de955a1-3d2d-46bc-9c4c-d2f92137a73a"
      ];
    };
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
    viewers = {
      mpv.enable = true;
      tdf.enable = true;
      zathura.enable = true;
    };
    editors = {
      default = "helix";
      helix.enable = true;
      vim.enable = true;
      zed.enable = true;
    };
  };

  programs = {
    firefox.enable = true;
    cli = {
      search.enable = true;
      system.enable = true;
    };
  };
};
```

The `tlp` power backend disables the conflicting power-profiles daemon, enables TLP’s compatible profile service, keeps UPower available for battery telemetry and desktop integration, applies the 75–80% charge window, and suspends on lid closure except while docked. The NVIDIA PRIME PCI bus IDs remain values in the `smunix` host manifest rather than reusable module defaults.

The command-line utility groups install `ack`, `ripgrep`, and `fd` through `modules.programs.cli.search`, and `coreutils` plus `pciutils` through `modules.programs.cli.system`.

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
| `Super+3` | `viewers` | Okular, Evince, Zathura, MPV, Xpdf; TDF runs inside the terminal |
| `Super+4` | `programming` | Zed (`zeditor`) |
| `Super+5` | `explorers` | Dolphin |
| `Super+6` | `chats` | Discord, Signal Desktop |
| `Super+7` | `dumpster` | Any normal application not matched by a more specific rule |

The Xpdf routing rule is included, but the pinned Xpdf 4.06 package is not installed because nixpkgs marks it insecure due to CVE-2023-26930. Okular, Evince, and Zathura are installed as the graphical document viewers; MPV is installed for media playback. TDF is enabled independently as a terminal PDF viewer; run `tdf document.pdf` from Ghostty, WezTerm, or XTerm.

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

## YubiKey authentication

The `smunix` host enables `modules.security.yubikey`. PAM treats a successful YubiKey touch as sufficient authentication for local PAM services, including SDDM login, login consoles, screen lockers, sudo, su, and polkit. If the key is absent or authentication fails, PAM continues to the normal password path so recovery remains possible.

The mapping is deployed centrally as `/etc/security/u2f_mappings`, which makes it available before an encrypted home directory is opened. The module also installs YubiKey Manager, PC/SC support, Yubico udev rules, and a rule that locks active sessions when a Yubico USB device is removed.

The previous `modules.security.passwordlessSudo` feature remains reusable but is not enabled for `smunix`, because a `NOPASSWD` sudo rule would bypass PAM and therefore bypass the YubiKey.

Before ending a root recovery shell, test the new configuration in another terminal:

```sh
sudo -i
sudo nixos-rebuild test --flake .#smunix
nix shell nixpkgs#pamtester -c pamtester login smunix authenticate
nix shell nixpkgs#pamtester -c pamtester sudo smunix authenticate
```

## LUKS FIDO2 unlocking

The `modules.security.luksFido2` feature enables the systemd-based initrd and explicitly includes its FIDO2 support. The `smunix` host selects both machine-specific entries already declared in `hosts/smunix/hardware.nix`: the encrypted root volume and encrypted swap volume. Each generated initrd crypttab row receives `fido2-device=auto`, which consumes the token metadata previously written to that volume by `systemd-cryptenroll`.

This configuration does not alter LUKS slots, erase passphrases, or suppress the recovery prompt. Keep at least one tested passphrase or recovery-key slot on every encrypted volume. If the key is unavailable or FIDO2 authentication fails, enter that passphrase when systemd asks for it. Because root and swap have independent LUKS2 headers, boot may require a separate key interaction for each volume.

Inspect both LUKS2 headers before scheduling the new boot generation:

```sh
sudo cryptsetup luksDump /dev/disk/by-uuid/cf3ef773-afb0-4a61-9c7c-ebb776b3d904
sudo cryptsetup luksDump /dev/disk/by-uuid/3de955a1-3d2d-46bc-9c4c-d2f92137a73a
```

Confirm that each header contains the expected `systemd-fido2` token, then build a boot generation without immediately replacing the running system:

```sh
sudo nixos-rebuild boot --flake .#smunix
```

Reboot with the YubiKey inserted and follow the early-boot prompt. Keep the passphrase available during this first boot. If the new initrd cannot unlock the root volume, select the previous NixOS generation from the bootloader and remove or correct the new configuration before trying again.

## Private secrets input

The non-flake `secrets` input points to a private repository and expects this layout:

```text
hosts/
└── smunix/
    ├── security/
    │   └── u2f_keys
    └── sops/
        └── example.yaml
.sops.yaml
```

The U2F mapping uses one user per line. The following values are deliberately fake:

```text
<username>:<key-handle>,<public-key>,es256,+presence
<username>:<first-handle>,<first-public-key>,es256,+presence:<second-handle>,<second-public-key>,es256,+presence
```

Future confidential values must be committed only in encrypted form. A mock encrypted SOPS document has this shape:

```yaml
service:
  api_token: ENC[AES256_GCM,data:MOCK_CIPHERTEXT,type:str]
sops:
  age:
    - recipient: age1mockrecipient000000000000000000000000000000000000000000000000
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        MOCK-ENCRYPTED-FILE-KEY
        -----END AGE ENCRYPTED FILE-----
  version: 3.9.0
```

Do not commit passwords, API tokens, recovery codes, private SSH keys, age identity files, unencrypted environment files, or decrypted SOPS output. A private repository controls remote access but does not encrypt the flake source after checkout; Nix copies input source files into the local Nix store during evaluation. The plain U2F mapping contains a credential handle and public key rather than the authenticator’s private key, but it still reveals identity and device metadata and should remain private.

The private input requires an authenticated Nix fetch. Do not place an access token in `flake.nix`, `nix.conf` managed by this repository, or the private source repository itself. With an authenticated GitHub CLI session, update and prefetch the input as the unprivileged user:

```sh
export NIX_CONFIG="access-tokens = github.com=$(gh auth token)"
nix flake lock --update-input secrets
nix flake archive
unset NIX_CONFIG
```

After changing the private repository, repeat those commands before rebuilding. If root cannot authenticate to the private input, evaluate and build as the authenticated user, then switch the already-built system closure:

```sh
export NIX_CONFIG="access-tokens = github.com=$(gh auth token)"
nix build .#nixosConfigurations.smunix.config.system.build.toplevel
unset NIX_CONFIG
sudo ./result/bin/switch-to-configuration switch
```
