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
    printing = {
      enable = true;
      networkDiscovery.enable = true;
    };
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
      powerManagement = {
        enable = false;
        finegrained = false;
      };
      prime = {
        sync.enable = true;
        offload = {
          enable = false;
          enableOffloadCmd = false;
        };
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  develop = {
    aya.enable = true;
    cc.enable = true;
    haskell.enable = true;
    python.enable = true;
    rust = {
      enable = true;
      nightlyVersion = "2026-07-15";
    };
    typst.enable = true;
    # quarto.enable = true;
  };

  shell = {
    default = "nushell";
    starship.enable = true;
    zellij.enable = true;
  };

  security = {
    fingerprint.enable = true;

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

  hardware.obsbot = {
    enable = true;
    usb.vendorId = "3564";
    video.deviceSymlink = "obsbot-tail2";
    audio = {
      enable = true;
      sourcePattern = "(obsbot|tail[ _-]?2|3564)";
      virtualSourceName = "obsbot_dji_mic";
      sampleRate = 48000;
      channels = 2;
      setDefault = true;
    };
    obs = {
      autoStart = true;
      collection = "Tail 2";
      profile = "Tail 2";
      scene = "Tail 2";
    };
  };

  vcs = {
    git.enable = true;
    jujutsu.enable = true;
  };

  desktop = {
    plasma.enable = true;
    niri = {
      enable = true;
      packageChannel = "unstable";
      monitorLayout = {
        enable = true;
        primaryOutput = "external";
        external = {
          connector = "DP-5";
          mode = "2560x1440@59.91";
          scale = 1;
          transform = "90";
          position = {
            x = 0;
            y = 0;
          };
          fullWidthColumns = true;
        };
        internal = {
          connector = "eDP-1";
          mode = "3840x2400@59.99";
          scale = 2;
          transform = "normal";
          position = {
            x = 1440;
            y = 0;
          };
        };
      };
      gammastep = {
        enable = true;
        locationProvider = "geoclue2";
        fallbackToManual = true;
        latitude = 45.529999;
        longitude = -73.930000;
        locationTimeoutSeconds = 20;
        dayTemperature = 6500;
        nightTemperature = 3500;
      };
    };
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
    obs = {
      enable = true;
      ndi.enable = true;
      virtualCamera = {
        enable = true;
        videoNr = 10;
      };
    };
    cli = {
      search.enable = true;
      system.enable = true;
    };
  };
};
```

The `tlp` power backend disables the conflicting power-profiles daemon, enables TLP’s compatible profile service, keeps UPower available for battery telemetry and desktop integration, applies the 75–80% charge window, and suspends on lid closure except while docked. The NVIDIA module exposes `powerManagement.enable`, `powerManagement.finegrained`, `prime.sync.enable`, `prime.offload.enable`, and `prime.offload.enableOffloadCmd` while keeping the PCI bus IDs host-specific. Existing hosts retain the previous power-managed offload defaults; `smunix` instead disables both NVIDIA power-management controls and PRIME offload, disables the `nvidia-offload` helper, and enables PRIME sync. Assertions reject simultaneous sync and offload, an offload command without offload mode, or fine-grained power management outside a power-managed offload configuration.

The command-line utility groups install `ack`, `ripgrep`, and `fd` through `modules.programs.cli.search`, and `coreutils` plus `pciutils` through `modules.programs.cli.system`.

The OBS module installs OBS Studio through NixOS's native wrapper. Enabling `modules.programs.obs.ndi` adds `pkgs.obs-studio-plugins.obs-ndi`, a compatibility alias for DistroAV—the plugin currently described by nixpkgs as formerly `obs-ndi`. DistroAV links the proprietary `ndi-6` SDK, so the repository's host package set must continue allowing unfree packages. The OBS overlay narrowly replaces only the `ndi-6` source archive hash because the vendor changed the file served at its stable download URL without the pinned nixpkgs expression being updated; DistroAV is rebuilt against that corrected SDK derivation. Enabling `modules.programs.obs.virtualCamera` configures the `v4l2loopback` kernel module and its `OBS Cam` device. The `virtualCamera.videoNr` option selects the numeric device suffix; `smunix` uses `10`, producing `/dev/video10` instead of competing with physical cameras near `/dev/video0`. Enabling OBS also installs `v4l-utils`, providing `v4l2-ctl` for listing and inspecting the loopback device. The module adds the primary user to `video` and `render`; log out and back in after activation so those supplementary groups are present in the session.

### OBSBOT Tail 2 automatic startup and DJI Mic 3 audio

The dedicated `modules.hardware.obsbot` module owns every Tail 2-specific setting. It matches the primary capture-capable Video4Linux interface below OBSBOT USB vendor `3564`, creates `/dev/obsbot-tail2`, and requests the `obsbot-tail2.service` Home Manager user unit. The UVC product ID remains optional because its value has not yet been recorded; obtain `ID_MODEL_ID` with `udevadm info --query=property --name=/dev/obsbot-tail2` and set `modules.hardware.obsbot.usb.productId` for stricter matching.

The user service waits for `/dev/obsbot-tail2`, `/dev/video10`, PipeWire, and the Tail 2 UVC audio endpoint. It locates that endpoint from PipeWire source metadata using `audio.sourcePattern`, creates the stable `obsbot_dji_mic` virtual microphone with `module-remap-source`, and makes it the temporary default source. This maps the DJI Mic 3 signal from the Tail 2 MIC IN path without per-session `pactl` commands. When the service stops, it unloads the virtual source and restores the prior default microphone.

Prepare OBS once through its GUI by creating a collection, profile, and scene named `Tail 2`. Add `/dev/obsbot-tail2` as the **Video Capture Device (V4L2)** source. Under **Settings → Audio**, set Mic/Auxiliary Audio to **Default** so the automatically selected `obsbot_dji_mic` source enters the stream; alternatively, add `obsbot_dji_mic` as a scene-level **Audio Capture Device (PulseAudio)** source. Use a 48 kHz OBS sample rate. `/dev/video10` carries video only, while the PipeWire source carries the DJI microphone audio.

After routing is ready, the service starts the saved collection, profile, and scene with `--startvirtualcam`. It verifies that `/dev/video10` becomes capture-capable before considering startup successful. Early OBS exit, missing devices, missing audio, or a virtual-camera readiness timeout causes cleanup and a failed unit state; systemd retries after five seconds, with at most three failed starts in two minutes. Desktop notifications report connection and virtual-camera failure states. The graphical-session dependency also handles a camera connected before login.

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

Unmatched normal applications default to `dumpster`; later application-specific rules override that fallback. Use `Super+Ctrl+1` through `Super+Ctrl+7` to move the focused column to the corresponding named workspace. All seven workspace declarations are generated with `open-on-output "DP-5"`, so each application’s existing `open-on-workspace` rule sends it to the correct named workspace on the external display whenever that output is connected.[2]

### ASUS portrait monitor layout

The previously selected stable Niri `25.08` rejects `layout` inside an `output` block because per-output layout overrides were introduced in Niri `25.11`.[1] The reusable module now exposes `packageChannel = "stable" | "unstable"` and asserts that `monitorLayout.enable` may be used only with the pinned unstable package. `smunix` selects `niri-unstable` from the existing flake input, while hosts that do not need per-output layout overrides retain the stable default.

The module generates the output fragment from typed `monitorLayout` options instead of hard-coding version-dependent syntax in the stable-compatible base KDL. It configures the external ASUS display on connector `DP-5` as a 2560×1440 output rotated 90 degrees counter-clockwise at position `(0, 0)`. Its explicit scale of `1` produces a 1440-pixel logical width after rotation. The built-in `eDP-1` panel uses 3840×2400 at scale `2`, producing a 1920×1200 logical area positioned at `(1440, 0)` immediately to the right. Niri calculates output placement in logical pixels after rotation and scaling.[1]

| Output | Mode | Transform and scale | Logical position | Column behavior |
|---|---|---|---|---|
| `DP-5` | `2560x1440@59.91` | 90° counter-clockwise, scale 1 | `x=0 y=0` | New columns default to the full output width. |
| `eDP-1` | `3840x2400@59.99` | Normal, scale 2 | `x=1440 y=0` | Uses the global widescreen column widths. |

The generated per-output `layout` override prevents new windows on the portrait display from opening as narrow half-width columns while leaving the laptop’s existing one-third, one-half, two-thirds, and full-width presets unchanged. `monitorLayout.primaryOutput = "external"` assigns `shell`, `internet`, `viewers`, `programming`, `explorers`, `chats`, and `dumpster` to `DP-5`; this makes it the effective primary application output rather than introducing a compositor-wide primary-monitor flag.

Niri cannot create a second workspace with the same name on `eDP-1`: every monitor has an independent workspace stack, but each named workspace is a single movable workspace. When `DP-5` connects, the assigned named workspaces—and any windows already on them—move to that output. When it disconnects, Niri moves them to an available monitor and remembers their assigned output for reconnection.[2] [3] The unchanged window rules continue routing newly opened applications by workspace name, so Firefox still opens in `internet`, Zed in `programming`, and unmatched applications in `dumpster`, now on `DP-5` while available.

Connector names and refresh rates come from the compositor and can change with a different dock or port. Verify the active names and exact modes after connecting the monitor:

```sh
niri msg outputs
niri validate -c ~/.config/niri/config.kdl
```

If the ASUS display appears under a connector other than `DP-5`, update `modules.desktop.niri.monitorLayout.external.connector`; the generated workspace assignments follow that option automatically. If Niri rejects either configured mode, replace the corresponding typed `monitorLayout` mode with the exact refresh rate reported by `niri msg outputs`. Do not move the generated per-output `layout` block back into the base KDL while using the stable package.

[1]: https://niri-wm.github.io/niri/Configuration%3A-Outputs.html "Niri output configuration"
[2]: https://niri-wm.github.io/niri/Configuration%3A-Named-Workspaces.html "Niri named workspaces and output assignment"
[3]: https://niri-wm.github.io/niri/Workspaces.html "Niri multi-monitor workspace behavior"

### Sunset-scheduled display warmth

The problem with enabling a color-temperature service for every graphical session is that it can conflict with Plasma’s native Night Light. The Niri module therefore owns Gammastep and attaches it specifically to `niri.service`: it starts after Niri, stops with Niri, and also checks that `XDG_CURRENT_DESKTOP=niri`. Logging into Plasma does not start Gammastep.

The reported failure did not mean that Wi-Fi was disabled. The evaluated host already uses NetworkManager with the compatible `wpa_supplicant` backend, Avahi is enabled, and GeoClue is configured to query BeaconDB. The current error means GeoClue received an empty access-point scan at lookup time. GeoClue uses nearby Wi-Fi identifiers for network location through `wpa_supplicant`; Avahi instead serves GeoClue’s network-NMEA source and is not required for ordinary Wi-Fi positioning.[4] [5]

The `smunix` host keeps `locationProvider = "geoclue2"` as the primary path. Before launching Gammastep, a Niri-only wrapper asks NetworkManager for a fresh scan and waits up to five two-second attempts for at least one BSSID. It then gives GeoClue 20 seconds to resolve a location. If that probe still fails, Gammastep starts with the approximate J0N 1P0 coordinates instead of leaving the display without a sunset schedule. GeoClue’s unused NMEA, 3G, CDMA, and modem-GPS sources are disabled, removing the unrelated Avahi/NMEA warning while leaving Wi-Fi location active.

Both the GeoClue agent and Gammastep are attached to `niri.service` and guarded by `XDG_CURRENT_DESKTOP=niri`; neither starts for Plasma. Gammastep keeps the display at a neutral `6500 K` during daylight, fades toward a warmer `3500 K` after sunset, and returns toward the daytime temperature around sunrise. Gammastep performs this twilight transition smoothly over roughly an hour.[6] Brightness remains at `1.0`, so the feature changes color temperature without reducing the physical backlight.

| Option | Selected value | Purpose |
|---|---:|---|
| `modules.desktop.niri.gammastep.enable` | `true` | Enables scheduled warm colors in the Niri session only. |
| `gammastep.locationProvider` | `"geoclue2"` | Uses automatic location as the primary provider. |
| `gammastep.fallbackToManual` | `true` | Keeps sunset scheduling operational when GeoClue cannot locate the host. |
| `gammastep.latitude`, `.longitude` | `45.529999`, `-73.930000` | Supplies the approximate J0N 1P0 fallback location. |
| `gammastep.locationTimeoutSeconds` | `20` | Bounds the automatic-location probe before fallback. |
| `gammastep.dayTemperature` | `6500` | Keeps daytime colors neutral. |
| `gammastep.nightTemperature` | `3500` | Reduces blue light with a visibly warmer nighttime profile. |

The GeoClue configuration allows Gammastep to request location without an interactive authorization prompt. Location-data submission remains disabled; GeoClue may still query the configured geolocation service to determine the current position. Inspect the access-point scan and complete service chain from a Niri terminal with:

```sh
nmcli -t -f BSSID device wifi list --rescan yes
systemctl status avahi-daemon geoclue
systemctl --user status geoclue-agent gammastep
systemctl --user restart gammastep
journalctl -b -u geoclue
journalctl --user -b -u geoclue-agent -u gammastep
```

When automatic lookup fails, the user journal records `Gammastep: GeoClue location unavailable; using configured manual fallback.` This is a controlled fallback rather than a service failure. Stopping Gammastep resets the color adjustment; starting it manually from Plasma is rejected by the Niri session condition. Plasma Night Light remains independently configurable through Plasma System Settings.

[4]: https://man.archlinux.org/man/geoclue "GeoClue configuration manual"
[5]: https://fedoramagazine.org/the-state-of-the-location-permission-on-fedora-linux-in-2025/ "GeoClue Wi-Fi positioning and wpa_supplicant"
[6]: https://man.archlinux.org/man/gammastep.1.en "Gammastep color-temperature scheduling"

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
| Move to another column | `Mod+H`/`Mod+Left` or `Mod+Right` | Focus the column to the left or right rather than changing tabs. `Super+L` is reserved for locking. |
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
| `Super+L`, `Ctrl+Alt+L`, or `Super+Alt+L` | Lock the session through Noctalia. |

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
| `Mod+Right` | Focus the column to the right; `Super+L` is reserved for locking. |
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
| `Mod+O` | Move only the focused window to the next monitor. With two outputs, repeated presses alternate between them. |

`Mod+O` invokes Niri’s native `move-window-to-monitor-next` action. It intentionally moves only the selected window; it does not duplicate or move the named workspace. Window rules are opening policies, so manually moving an existing window does not rerun its `open-on-workspace` rule. Newly opened windows remain routed to their configured named workspace on `DP-5`. To move every window in the current column instead, retain the directional `Mod+Ctrl+Shift+Arrow` bindings shown above.

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

## Network printer discovery

The `smunix` host enables `modules.hardware.printing.networkDiscovery`. The printing module starts CUPS for local queue management, Avahi for multicast DNS and DNS-SD discovery, the IPv4 NSS plug-in for resolving printer names ending in `.local`, and `cups-browsed` for automatically creating queues from compatible network announcements.[7] [8]

| Option | Default | Purpose |
|---|---:|---|
| `modules.hardware.printing.networkDiscovery.enable` | `false` | Enables Avahi-based discovery for network printers. The `smunix` host explicitly turns it on. |
| `networkDiscovery.autoCreateQueues` | `true` | Runs `cups-browsed` so compatible DNS-SD printers can appear as local CUPS queues automatically. |
| `networkDiscovery.resolveLocalNames` | `true` | Enables IPv4 `.local` host-name resolution through Avahi. |
| `networkDiscovery.openFirewall` | `true` | Allows inbound mDNS discovery traffic on UDP port 5353. |
| `modules.hardware.printing.drivers` | `[]` | Adds legacy CUPS drivers when a printer does not support driverless IPP Everywhere or AirPrint. |

The module does **not** advertise queues owned by this computer and does not expose the local CUPS server to the LAN. Only the mDNS discovery port is opened. Printer administration remains available locally through **System Settings → Printers** in Plasma or `http://localhost:631`; Niri can use the same local CUPS page in a browser.

After activating the configuration, inspect the discovery services and advertised IPP endpoints:

```sh
systemctl status cups avahi-daemon cups-browsed
avahi-browse --resolve --terminate _ipp._tcp
avahi-browse --resolve --terminate _ipps._tcp
lpinfo -v
lpstat -e
lpstat -v
```

A compatible printer may appear automatically in `lpstat -e`. If it is discovered but no persistent queue is created, add it through Plasma Printer Settings or the local CUPS page and select the driverless entry. A known IPP endpoint can also be added explicitly:

```sh
sudo lpadmin -p office-printer \
  -E \
  -v 'ipps://printer.local/ipp/print' \
  -m everywhere
lpoptions -d office-printer
lp -d office-printer document.pdf
lpstat -t
```

Replace the example name and URI with those reported by `avahi-browse` or the printer. Prefer `ipps://` when the device advertises it. For an older printer that requires a model-specific driver, add a package declaratively instead of installing it imperatively:

```nix
modules.hardware.printing = {
  enable = true;
  drivers = with pkgs; [
    gutenprint
    hplip
  ];
  networkDiscovery.enable = true;
};
```

mDNS discovery normally requires the computer and printer to share a multicast-capable LAN. Guest Wi-Fi client isolation, VLAN boundaries, or a router that suppresses multicast can prevent automatic discovery even when direct IP printing works. In that situation, use the printer’s stable `ipp://` or `ipps://` URI, or configure multicast forwarding on the network rather than exposing this computer’s CUPS server. Review failures with:

```sh
journalctl -b -u avahi-daemon -u cups-browsed -u cups
```

[7]: https://openprinting.github.io/cups/doc/network.html "CUPS network printer guidance"
[8]: https://avahi.org/ "Avahi multicast DNS and DNS-SD"

## Home Manager conflict backups

The shared root module configures `home-manager.backupCommand` with a generated backup script. When Home Manager encounters an unmanaged file at a path it must control, the script moves that file to a sibling path using this format:

```text
<original-path>.backup-<UTC timestamp>
```

The timestamp includes nanoseconds, and the script adds a numeric suffix if the generated destination already exists. Existing backups are never overwritten. This replaces the previous fixed `.backup` extension, so a file such as `~/.gtkrc-2.0.backup` cannot block a later activation.

## Fingerprint authentication and automatic locking

The `smunix` host enables `modules.security.fingerprint`, which activates fprintd and its PAM module. Fingerprints are accepted for interactive SDDM, console login, Plasma fingerprint unlock, Noctalia and Swaylock unlock, sudo, su, polkit, and systemd-run0 prompts. Fingerprint authentication is explicitly disabled for password changes, user and group administration, autologin helpers, and other noninteractive PAM services.

The desktop modules enforce the following automatic-lock policy:

| Session | Idle lock | Additional behavior | Fingerprint PAM service |
|---|---:|---|---|
| Plasma | 10 minutes | Zero-second grace period and authentication after resume | `kde-fingerprint` |
| Niri with Noctalia | 600 seconds | Displays switch off after another 60 seconds and the session locks before suspend | `login` |
| Swaylock when launched manually | Not responsible for the idle timer | Uses the same enrolled database | `swaylock` |

Niri uses Noctalia as its active lock screen rather than Swaylock. Swaylock fingerprint support remains enabled for manual use or a future Sway session. Plasma deliberately keeps its generic `kde` PAM service password-only and uses `kde-fingerprint` for biometric unlock, preventing the fingerprint conversation from blocking password entry.

The generated PAM order keeps the existing recovery paths: YubiKey U2F is attempted first, fingerprint authentication is attempted next, and the normal password remains available afterward. A fingerprint does not unlock the LUKS volumes during early boot; that remains the responsibility of the enrolled YubiKey FIDO2 token or a LUKS passphrase.

The configured enrollment set contains both index fingers:

```nix
enrollment.fingers = [
  "left-index-finger"
  "right-index-finger"
];
```

After activating the configuration, enroll that complete set as `smunix` without `sudo`:

```sh
fingerprint-enroll-configured
```

The helper calls `fprintd-enroll` for each configured finger and lists the resulting database. It also accepts an explicit subset or additional valid fingers:

```sh
fingerprint-enroll-configured left-thumb right-thumb
```

List and verify the configured prints with:

```sh
fingerprint-list
fingerprint-verify-configured
```

Verification is interactive and requests each configured finger in sequence. To verify only selected fingers, pass them explicitly:

```sh
fingerprint-verify-configured left-index-finger right-index-finger
```

The underlying fprintd commands remain available for individual operations:[9]

```sh
fprintd-enroll -f right-index-finger
fprintd-list "$USER"
fprintd-verify -f right-index-finger
fprintd-delete "$USER"
```

Plasma can also enroll fingerprints through **System Settings → Users → Configure Fingerprint Authentication** when the reader is supported by libfprint. The CLI and desktop panel use the same fprintd database under `/var/lib/fprint/`; no biometric template is stored in this repository.[9] [10]

Keep a root recovery shell open during initial testing. In another terminal, test interactive authentication before logging out:

```sh
sudo -i
sudo nixos-rebuild test --flake .#smunix
fingerprint-verify-configured
sudo -k
sudo true
```

Test the fingerprint, YubiKey, and password paths separately. If enrollment reports that no device is available, inspect the sensor with `lsusb` and `journalctl -u fprintd`; the standard module cannot make an unsupported reader work, and some sensors require a vendor-specific Touch OEM Driver package.

[9]: https://man.archlinux.org/man/fprintd.1 "fprintd command-line utilities"
[10]: https://fprint.freedesktop.org/fprintd-dev/Device.html "fprintd device interface and enrollment behavior"

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

### Rotating the Kimi Code key

The managed Kimi Code configuration uses the OAuth-style **`key`** fields from the complete exported configuration, not the legacy `api_key` fields. Keep every `api_key` value empty and place the same replacement credential in each of these three `key` fields. The values below are deliberately fake:

```toml
[providers."managed:kimi-code"]
api_key = ""

[providers."managed:kimi-code".oauth]
key = "mock_kimi_key_never_commit_a_real_value"

[services.moonshot_fetch]
api_key = ""

[services.moonshot_fetch.oauth]
key = "mock_kimi_key_never_commit_a_real_value"

[services.moonshot_search]
api_key = ""

[services.moonshot_search.oauth]
key = "mock_kimi_key_never_commit_a_real_value"
```

Edit the **complete** configuration rather than replacing it with only this excerpt, because the file also defines models, capabilities, service endpoints, and the default model. Use a restrictive umask, encrypt the complete file to every public key in `.age-recipients`, verify that the current private identity can decrypt the result, and securely remove temporary plaintext:

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

## Aya and eBPF development

The problem with developing eBPF directly on the workstation is that loading test programs requires elevated kernel access and a failed program can disturb host networking or security hooks. `modules.develop.aya` therefore installs the build and inspection tools on `smunix`, while `ebpf-vm` runs programs in a disposable NixOS VM with the required BPF kernel features. Aya development requires Rust nightly with `rust-src`, `bpf-linker`, `cargo-generate`, and `bpftool`.[11] The `aya-tool` command generates Rust bindings for selected Linux kernel types and requires both `bpftool` and `bindgen`; the packaged wrapper supplies those dependencies automatically.[13]

The Rust module is the single owner of the host toolchain version. `modules.develop.rust.nightlyVersion = "2026-07-15"` resolves a rust-overlay toolchain containing Cargo, rustc, rustfmt, Clippy, rust-analyzer, and `rust-src`. Aya requires the Rust module and reuses its read-only resolved `toolchain`; it no longer has a separate version option that can drift out of sync with the linker.

| Component | Selected implementation |
|---|---|
| Rust toolchain | Shared `modules.develop.rust.nightlyVersion = "2026-07-15"`, with `rust-src`, rustfmt, Clippy, and rust-analyzer |
| BPF linker | Official static `bpf-linker` 0.11.1 x86_64-musl artifact with the supplied fixed hash |
| Build command | `aya-cargo`, with `ebpf-cargo` as a shell alias |
| Kernel bindings | `aya-tool` with wrapped `bpftool`, `bindgen`, and libclang dependencies; installed on both the host and VM |
| Inspection and tracing tools | `bpftool`, `bpftrace` 0.25.1, `pahole`, `llvm-objdump`, and `tcpdump`; installed on both the host and VM |
| Virtualization access | The primary user is added to `kvm`; log out and back in after activation |
| Guest resources | Four virtual CPUs and 4096 MiB RAM |
| Shared source | The requested host directory is mounted at `/host` through VirtFS/9P[12] |
| SSH access | Host loopback `127.0.0.1:2222` forwards to guest TCP port 22; only `dev` may log in, with automatic host public-key authorization and `dev` password fallback |

Plain `cargo`, `rustc`, `rustfmt`, `clippy`, and `rust-analyzer` use the configured nightly throughout the host. `aya-cargo` is the eBPF-specific wrapper: it selects that same nightly explicitly, exports its Rust source tree, and puts the exact `bpf-linker` first on `PATH`:

```sh
aya-cargo build
aya-cargo clippy
aya-rustc --version
bpf-linker --version
bpftool version
bpftrace --version
aya-tool --help
```

Use `bpftrace` for concise, dynamic eBPF tracing on either the host or inside `ebpf-vm`; attaching probes normally requires elevated privileges.[14]

```sh
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%s\\n", comm); }'
```

Generate bindings for one or more kernel types on either the host or inside `ebpf-vm`:

```sh
aya-tool generate task_struct > vmlinux.rs
aya-tool generate task_struct dentry > vmlinux.rs
```

The `ebpf-vm` command requires the named `--shared-directory` parameter. Relative paths are canonicalized before the generated NixOS VM runner changes into its temporary working directory. The launcher automatically selects the first public key present in `~/.ssh/id_ed25519.pub`, `id_ed25519_sk.pub`, `id_ecdsa.pub`, `id_ecdsa_sk.pub`, or `id_rsa.pub` and authorizes it for the guest `dev` account:

```sh
ebpf-vm --shared-directory "$PWD"
ebpf-vm --shared-directory="$HOME/src/my-aya-project"
```

Select another public key explicitly either by option or environment variable:

```sh
ebpf-vm --shared-directory "$PWD" --ssh-public-key "$HOME/.ssh/work.pub"
EBPF_VM_SSH_PUBLIC_KEY_FILE="$HOME/.ssh/work.pub" ebpf-vm --shared-directory "$PWD"
```

The selected file must contain exactly one valid OpenSSH public key. The public key becomes part of the generated VM configuration and may be stored in the Nix store; the launcher never reads or copies the corresponding private key. Use `--no-ssh-key` to disable injection for one launch and retain password-only access.

The selected directory appears as `/host` inside the guest. Any arguments after `--` are passed to QEMU:

```sh
ebpf-vm --shared-directory "$PWD" -- -nographic
```

The launcher rejects a missing parameter, nonexistent directory, or unknown option before QEMU starts. Its built-in reference is available with `ebpf-vm --help`.

After the VM reaches its login prompt, connect from the host through the loopback-only forwarded port. OpenSSH should use the automatically authorized matching private key:

```sh
ssh -o StrictHostKeyChecking=accept-new -p 2222 dev@127.0.0.1
```

For an explicitly selected key whose private half is not a standard SSH identity filename, pass that private-key path when connecting:

```sh
ssh -o StrictHostKeyChecking=accept-new -i "$HOME/.ssh/work" -p 2222 dev@127.0.0.1
```

| SSH user | Password | Access policy |
|---|---|---|
| `dev` | `dev` | Allowed; the injected host public key is preferred, while this password remains a recovery path. The account belongs to `wheel` and has passwordless sudo inside the disposable VM |
| `root` | None for SSH | Denied by `PermitRootLogin = "no"`; root autologin remains available only on the VM console |
| Any other account | Not applicable | Denied by the explicit OpenSSH `AllowUsers dev` policy |

The QEMU forward binds only to `127.0.0.1`, so TCP port 2222 is reachable from the host itself rather than the surrounding LAN. Recreating the disposable VM can generate a different SSH host key. If OpenSSH reports a changed key after deliberate VM replacement, remove only this loopback-port entry and reconnect:

```sh
ssh-keygen -R '[127.0.0.1]:2222'
ssh -o StrictHostKeyChecking=accept-new -p 2222 dev@127.0.0.1
```

The VM enables `BPF_SYSCALL`, JIT compilation, BTF kernel metadata, BPF LSM support, cgroups, namespaces, seccomp filtering, and audit support. It explicitly places `bpf` in the active LSM order. The guest includes `aya-tool`, `bpftool`, `bpftrace`, `pahole`, `iproute2`, and `tcpdump`. **The `dev`/`dev` credentials, passwordless sudo, and root console autologin are intentionally unsafe and belong only to the disposable laboratory VM; never copy them to a persistent host or production image.**

Inside the VM, inspect the environment with:

```sh
cd /host
uname -a
bpftool feature probe kernel
bpftool btf show
cat /sys/kernel/security/lsm
```

The first VM invocation may build or download a substantial NixOS and QEMU closure. Later launches reuse the Nix store and are faster. Stop the VM normally with `poweroff` from the guest.

[11]: https://aya-rs.dev/book/start/development.html "Aya development environment"
[12]: https://nixos.org/manual/nixos/stable/#sec-qemu-vm "NixOS QEMU virtual machines"
[13]: https://aya-rs.dev/book/aya/aya-tool.html "Using aya-tool"
[14]: https://bpftrace.org/docs/release_025/docs "bpftrace 0.25 documentation"
