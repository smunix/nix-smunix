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
  ai = {
    enable = true;
    client = "kimi";
  };

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
    fonts.compact = {
      enable = true;
      reduction = 20;
    };
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

The AI module provides one host-level switch and a typed client selector. Selecting `"kimi"` installs the upstream Kimi Code package exposed as `pkgs.kimi-code` by the repository overlay; run it with `kimi`. The selector currently accepts only Kimi, while its package map and enum provide the extension point for a future Claude Code client. For Kimi, the module also decrypts the host-specific age payload from the private input at user-login time and installs `~/.kimi-code/config.toml` with mode `0600`; the plaintext API key never enters the Nix store.

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

Niri uses resolution-independent widescreen column proportions. Shell, viewer, and chat applications open at one-half width; browsers and Zed open at two-thirds width; Dolphin opens at one-third width. Unmatched applications retain the full-width fallback in `dumpster`, while Noctalia’s settings window remains floating. A single column is centered, and focused columns are centered only when the visible layout overflows. The persistent named workspaces route applications as follows:

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

Unmatched normal applications default to `dumpster`; later application-specific rules override that fallback. Use `Super+Ctrl+1` through `Super+Ctrl+7` to move the focused column to the corresponding named workspace.

## Niri keybinding reference

Niri is operated primarily through compositor shortcuts, so this reference mirrors every active binding in `modules/nixos/desktop/niri/config.kdl`. **`Mod` means the Super/Windows key.** Where both arrow keys and `H`, `J`, `K`, or `L` are shown, either form performs the same action.

> Press `Mod+Shift+/` at any time to show Niri’s built-in hotkey overlay.

### Working with tabbed columns

Tabbed mode changes how multiple windows in the **same column** are displayed; it does not create a separate workspace or namespace. The important distinction is that vertical navigation switches windows inside the column, while horizontal navigation switches between columns.

| Task | Keys | Result |
|---|---|---|
| Add a window to a column | `Mod+,` | Consume the focused window into a neighboring column so the windows can form a stack. |
| Toggle tabbed mode | `Mod+W` | Switch the focused column between normal stacked display and tabbed display. |
| Select the next tab | `Mod+J` or `Mod+Down` | Focus the next window in the current column. |
| Select the previous tab | `Mod+K` or `Mod+Up` | Focus the previous window in the current column. |
| Reorder a tab downward | `Mod+Ctrl+J` or `Mod+Ctrl+Down` | Move the focused window down within the current column. |
| Reorder a tab upward | `Mod+Ctrl+K` or `Mod+Ctrl+Up` | Move the focused window up within the current column. |
| Move to another column | `Mod+H`/`Mod+Left` or `Mod+L`/`Mod+Right` | Focus the column to the left or right rather than changing tabs. |
| Remove a window from the stack | `Mod+.` | Expel the focused window into its own column. |
| Consume or expel by direction | `Mod+[` or `Mod+]` | Consume or expel the focused window toward the left or right column. |

A practical sequence is to place the desired windows on one workspace, use `Mod+,` to combine them into one column, press `Mod+W` to show that column as tabs, and then use `Mod+J` and `Mod+K` to switch between those windows.

### Applications and Noctalia

| Keys | Action |
|---|---|
| `Mod+Return` | Open Ghostty. |
| `Mod+D`, `Mod+Space`, or `XF86Search` | Toggle the Noctalia application launcher. |
| `Mod+Shift+V` | Toggle clipboard history. |
| `Mod+C` | Open the launcher in calculator mode. |
| `Mod+S` | Toggle Control Center. |
| `Mod+E` | Toggle the session menu. |
| `Mod+Shift+W` | Toggle the wallpaper picker. |
| `Mod+Shift+,` | Toggle Noctalia settings. |
| `Mod+Shift+D` | Toggle desktop-widget editing. |
| `Alt+Tab` | Open the Noctalia window switcher. |
| `Ctrl+Alt+L` or `Super+Alt+L` | Lock the session. |

### Audio, media, and brightness

These hardware keys continue working while the session is locked.

| Keys | Action |
|---|---|
| `XF86AudioRaiseVolume` | Increase output volume. |
| `XF86AudioLowerVolume` | Decrease output volume. |
| `XF86AudioMute` | Toggle output mute. |
| `XF86AudioMicMute` | Toggle microphone mute. |
| `XF86AudioPlay` | Toggle media playback. |
| `XF86AudioStop` | Stop media playback. |
| `XF86AudioPrev` | Play the previous media item. |
| `XF86AudioNext` | Play the next media item. |
| `XF86MonBrightnessUp` | Increase display brightness. |
| `XF86MonBrightnessDown` | Decrease display brightness. |

### Window, column, and monitor navigation

| Keys | Action |
|---|---|
| `Mod+Left` or `Mod+H` | Focus the column to the left. |
| `Mod+Right` or `Mod+L` | Focus the column to the right. |
| `Mod+Up` or `Mod+K` | Focus the window above in the current column. |
| `Mod+Down` or `Mod+J` | Focus the window below in the current column. |
| `Mod+Ctrl+Left` or `Mod+Ctrl+H` | Move the focused column left. |
| `Mod+Ctrl+Right` or `Mod+Ctrl+L` | Move the focused column right. |
| `Mod+Ctrl+Up` or `Mod+Ctrl+K` | Move the focused window up within its column. |
| `Mod+Ctrl+Down` or `Mod+Ctrl+J` | Move the focused window down within its column. |
| `Mod+Shift+Left` or `Mod+Shift+H` | Focus the monitor to the left. |
| `Mod+Shift+Right` or `Mod+Shift+L` | Focus the monitor to the right. |
| `Mod+Shift+Up` or `Mod+Shift+K` | Focus the monitor above. |
| `Mod+Shift+Down` or `Mod+Shift+J` | Focus the monitor below. |
| `Mod+Ctrl+Shift+Left` or `Mod+Ctrl+Shift+H` | Move the focused column to the monitor on the left. |
| `Mod+Ctrl+Shift+Right` or `Mod+Ctrl+Shift+L` | Move the focused column to the monitor on the right. |
| `Mod+Ctrl+Shift+Up` or `Mod+Ctrl+Shift+K` | Move the focused column to the monitor above. |
| `Mod+Ctrl+Shift+Down` or `Mod+Ctrl+Shift+J` | Move the focused column to the monitor below. |

### Workspace navigation

| Keys | Action |
|---|---|
| `Mod+Page Up` or `Mod+I` | Focus the previous workspace. |
| `Mod+Page Down` or `Mod+U` | Focus the next workspace. |
| `Mod+Ctrl+Page Up` or `Mod+Ctrl+I` | Move the focused column to the previous workspace. |
| `Mod+Ctrl+Page Down` or `Mod+Ctrl+U` | Move the focused column to the next workspace. |
| `Mod+Shift+Page Up` or `Mod+Shift+I` | Move the current workspace up. |
| `Mod+Shift+Page Down` or `Mod+Shift+U` | Move the current workspace down. |
| `Mod+mouse wheel up` | Focus the previous workspace. |
| `Mod+mouse wheel down` | Focus the next workspace. |
| `Mod+Ctrl+mouse wheel up` | Move the focused column to the previous workspace. |
| `Mod+Ctrl+mouse wheel down` | Move the focused column to the next workspace. |

### Named workspaces

| Focus | Move focused column | Workspace |
|---|---|---|
| `Mod+1` | `Mod+Ctrl+1` | `shell` |
| `Mod+2` | `Mod+Ctrl+2` | `internet` |
| `Mod+3` | `Mod+Ctrl+3` | `viewers` |
| `Mod+4` | `Mod+Ctrl+4` | `programming` |
| `Mod+5` | `Mod+Ctrl+5` | `explorers` |
| `Mod+6` | `Mod+Ctrl+6` | `chats` |
| `Mod+7` | `Mod+Ctrl+7` | `dumpster` |

### Layout, columns, and tabs

| Keys | Action |
|---|---|
| `Mod+[` | Consume or expel the focused window toward the left column. |
| `Mod+]` | Consume or expel the focused window toward the right column. |
| `Mod+,` | Consume the focused window into the neighboring column. |
| `Mod+.` | Expel the focused window from its column. |
| `Mod+R` | Cycle the focused column through one-third, one-half, two-thirds, and full-width presets. |
| `Mod+W` | Toggle the focused column between normal and tabbed display. |
| `Mod+Shift+R` | Cycle the focused window through preset heights. |
| `Mod+Ctrl+R` | Reset the focused window’s height. |
| `Mod+F` | Toggle maximization of the focused column. |
| `Mod+Shift+F` | Toggle fullscreen for the focused window. |
| `Mod+V` | Toggle the focused window between tiled and floating layouts. |
| `Mod+Ctrl+F` | Expand the focused column into the currently available width. |
| `Mod+Ctrl+C` | Center all visible columns. |
| `Mod+-` or `Mod+=` | Decrease or increase the focused column width by 10%. |
| `Mod+Shift+-` or `Mod+Shift+=` | Decrease or increase the focused window height by 10%. |

### Screenshots and session controls

| Keys | Action |
|---|---|
| `Print` | Capture an interactively selected region through Noctalia. |
| `Ctrl+Print` | Capture the entire screen through Noctalia. |
| `Alt+Print` | Capture the focused window through Niri. |
| `Mod+Escape` | Toggle whether the focused application may inhibit compositor shortcuts. |
| `Mod+Q` | Close the focused window. |
| `Mod+Shift+P` | Turn off the displays. |
| `Mod+Shift+E` | Exit Niri. |
| `Ctrl+Alt+Delete` | Toggle the Noctalia session menu. |

The compact-font feature provides a shared reduction percentage so desktop toolkits and individual applications do not drift to different scales. `modules.desktop.fonts.compact.reduction` accepts `5`, `10`, `15`, `20`, `25`, `30`, or `35`; `smunix` selects **20%**. The derived factor is applied to Noctalia, GTK, Qt, KDE, X11, Ghostty, WezTerm, and Zed. Application-specific document or web-page zoom remains controlled by the application.

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

## Home Manager conflict backups

The shared root module configures `home-manager.backupCommand` with a generated backup script. When Home Manager encounters an unmanaged file at a path it must control, the script moves that file to a sibling path using this format:

```text
<original-path>.backup-<UTC timestamp>
```

The timestamp includes nanoseconds, and the script adds a numeric suffix if the generated destination already exists. Existing backups are never overwritten. This replaces the previous fixed `.backup` extension, so a file such as `~/.gtkrc-2.0.backup` cannot block a later activation.

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
    ├── apps/
    │   └── kimi-code/
    │       └── config.toml.age
    ├── security/
    │   └── u2f_keys
    └── sops/
        └── example.yaml
.age-recipients
.sops.yaml
```

The U2F mapping uses one user per line. The following values are deliberately fake:

```text
<username>:<key-handle>,<public-key>,es256,+presence
<username>:<first-handle>,<first-public-key>,es256,+presence:<second-handle>,<second-public-key>,es256,+presence
```

The problem this repository solves is that application credentials must be reproducible without becoming public, entering Git history as plaintext, or being copied into the Nix store unencrypted. The private repository therefore contains only encrypted application payloads and public recipient metadata. **Private decryption keys never belong in `nix-secrets`; they remain on the machine under `~/.ssh`.**

### Updating `nix-secrets`

Clone the private repository once, or update an existing checkout before making changes:

```sh
gh repo clone smunix/nix-secrets ~/src/nix-secrets
cd ~/src/nix-secrets
git pull --ff-only
```

Make the required encrypted or public-metadata change, then review only file names and statistics before committing. Never stage a plaintext configuration:

```sh
git status --short
git diff --check
git diff --stat
git add .age-recipients hosts/smunix/apps/kimi-code/config.toml.age
git commit -m "chore: rotate Kimi credentials"
git push
```

After every private-repository push, update the pinned `secrets` revision in `nix-smunix`. The private input uses SSH transport, so run the update and build as `smunix` while the SSH identity or agent can access `nix-secrets`; do not run the fetch as root. Switch only the already-built closure with `sudo`:

```sh
cd ~/nix-config
ssh-add -l
nix flake lock --update-input secrets
nix build .#nixosConfigurations.smunix.config.system.build.toplevel

git add flake.lock
git commit -m "chore: update private secrets input"
sudo ./result/bin/switch-to-configuration switch
systemctl --user restart kimi-code-config.service
```

Verify the service and permissions without printing the secret:

```sh
systemctl --user status kimi-code-config.service
stat -c '%a %n' ~/.kimi-code ~/.kimi-code/config.toml
kimi
```

The expected modes are `700` for `~/.kimi-code` and `600` for `config.toml`.

### Rotating the Kimi API key

Create the replacement TOML in a private temporary file. The example value below is deliberately fake:

```toml
[providers.moonshot]
api_key = "mock_api_key_never_commit_a_real_value"
```

Use a restrictive umask, encrypt the complete file to every public key in `.age-recipients`, verify that the current private identity can decrypt the result, and securely remove temporary plaintext:

```sh
cd ~/src/nix-secrets
umask 077
plain="$(mktemp)"
cipher="$(mktemp)"
trap 'shred -u "$plain" "$cipher" 2>/dev/null || rm -f "$plain" "$cipher"' EXIT

$EDITOR "$plain"
age -R .age-recipients < "$plain" > "$cipher"
age --decrypt --identity ~/.ssh/id_ed25519 "$cipher" >/dev/null
install -m 0644 "$cipher" hosts/smunix/apps/kimi-code/config.toml.age
shred -u "$plain"
```

Commit and push only the `.age` file, then follow the `nix-secrets` lock-update and deployment procedure above. Keep the previous private-repository commit available until `kimi` authenticates successfully. If the new API key fails, revert the private-repository commit instead of force-pushing history, update the `secrets` lock again, and redeploy.

### Rotating the age/SSH decryption identity

An age recipient is the **public** half of an SSH key. The matching private key must remain local and must never be copied into either Git repository. Rotate recipients in two stages so the old key continues to provide recovery until the new key is proven.

First, create a new local identity and retain the old one:

```sh
umask 077
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_next
cat ~/.ssh/id_ed25519_next.pub
```

Append the displayed public key to `.age-recipients` without removing the old recipient. Re-encrypt every `.age` payload to the combined recipient set. The following pipeline keeps plaintext off disk:

```sh
cd ~/src/nix-secrets
cipher="$(mktemp)"
trap 'rm -f "$cipher"' EXIT

age --decrypt --identity ~/.ssh/id_ed25519 \
  hosts/smunix/apps/kimi-code/config.toml.age \
  | age -R .age-recipients > "$cipher"

age --decrypt --identity ~/.ssh/id_ed25519_next "$cipher" >/dev/null
install -m 0644 "$cipher" hosts/smunix/apps/kimi-code/config.toml.age
```

If the new identity uses a non-default path, add it to the host configuration before retiring the old key:

```nix
modules.ai.kimi.identityPaths = [
  "/home/smunix/.ssh/id_ed25519_next"
  "/home/smunix/.ssh/id_ed25519"
];
```

Commit and push the updated `.age-recipients` and every re-encrypted payload, update the `secrets` lock, deploy, restart `kimi-code-config.service`, and confirm that the new identity works. To test the new key independently, temporarily stop or rename the old private key only after keeping a separate recovery terminal open.

After successful deployment, remove the old public recipient from `.age-recipients`, re-encrypt every payload again using the new recipient set, repeat the lock update and deployment, and only then archive or securely destroy the old private key. Never remove an old recipient before all payloads have been re-encrypted and tested with the replacement key.

### Other encrypted payloads

SOPS-encrypted documents remain available for future structured secrets. A mock encrypted SOPS document has this shape:

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

Do not commit passwords, API tokens, recovery codes, private SSH keys, age identity files, unencrypted application configurations, environment files, or decrypted SOPS output. A private repository controls remote access but does not encrypt the flake source after checkout; Nix copies input source files into the local Nix store during evaluation. The plain U2F mapping contains a credential handle and public key rather than the authenticator’s private key, but it still reveals identity and device metadata and should remain private.
