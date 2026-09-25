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
    clients = [
      "kimi"
      "antigravity"
    ];
  };

  ide = {
    enable = true;
    ides = [
      "antigravity"
      "zed"
    ];
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
    dioxus = {
      enable = true;
      desktop = {
        enable = true;
        libclangPackage = pkgs.llvmPackages.libclang;
      };
      developmentServer = {
        enable = true;
        address = "127.0.0.1";
        port = 8080;
        openFirewall = false;
        caddy = {
          enable = true;
          networkInterface = "wlp0s20f3";
          tlsMode = "internal";
          openFirewall = true;
        };
      };
      web = {
        enable = true;
        wasmBindgenCliPackage = pkgs.wasm-bindgen-cli_0_2_128;
      };
      android = {
        enable = true;
        platformVersion = "35";
        buildToolsVersion = "35.0.0";
        ndkVersion = "27.2.12479018";
        cmakeVersion = "3.22.1";
        includeEmulator = true;
        includeSystemImage = true;
        rustTargets = [
          "aarch64-linux-android"
          "armv7-linux-androideabi"
          "i686-linux-android"
          "x86_64-linux-android"
        ];
      };
    };
    haskell.enable = true;
    python.enable = true;
    rust = {
      enable = true;
      channel = "stable";
      version = "1.98.1";
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
    bottles.enable = true;
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

The Bottles module (`modules.programs.bottles.enable`) provisions the Bottles Windows environment manager via Flatpak. It enables the system Flatpak service and XDG desktop portals, provisions the Flathub remote and installs `com.usebottles.bottles` through a declarative systemd oneshot service, grants host filesystem access (`--filesystem=host`) so Windows prefixes can interact with host files and project scratchpads, and provides `bottles` and `bottles-cli` command-line wrappers.

### OBSBOT Tail 2 automatic startup and DJI Mic 3 audio

The dedicated `modules.hardware.obsbot` module owns every Tail 2-specific setting. It matches the primary capture-capable Video4Linux interface below OBSBOT USB vendor `3564`, creates `/dev/obsbot-tail2`, and requests the `obsbot-tail2.service` Home Manager user unit. The UVC product ID remains optional because its value has not yet been recorded; obtain `ID_MODEL_ID` with `udevadm info --query=property --name=/dev/obsbot-tail2` and set `modules.hardware.obsbot.usb.productId` for stricter matching.

The user service waits for `/dev/obsbot-tail2`, `/dev/video10`, PipeWire, and the Tail 2 UVC audio endpoint. It locates that endpoint from PipeWire source metadata using `audio.sourcePattern`, creates the stable `obsbot_dji_mic` virtual microphone with `module-remap-source`, and makes it the temporary default source. This maps the DJI Mic 3 signal from the Tail 2 MIC IN path without per-session `pactl` commands. When the service stops, it unloads the virtual source and restores the prior default microphone.

Prepare OBS once through its GUI by creating a collection, profile, and scene named `Tail 2`. Add `/dev/obsbot-tail2` as the **Video Capture Device (V4L2)** source. Under **Settings → Audio**, set Mic/Auxiliary Audio to **Default** so the automatically selected `obsbot_dji_mic` source enters the stream; alternatively, add `obsbot_dji_mic` as a scene-level **Audio Capture Device (PulseAudio)** source. Use a 48 kHz OBS sample rate. `/dev/video10` carries video only, while the PipeWire source carries the DJI microphone audio.

After routing is ready, the service starts the saved collection, profile, and scene with `--startvirtualcam`. It verifies that `/dev/video10` becomes capture-capable before considering startup successful. Early OBS exit, missing devices, missing audio, or a virtual-camera readiness timeout causes cleanup and a failed unit state; systemd retries after five seconds, with at most three failed starts in two minutes. Desktop notifications report connection and virtual-camera failure states. The graphical-session dependency also handles a camera connected before login.

The AI module provides one host-level switch and a typed `clients` list, so several coding agents can be installed together. The `smunix` host selects both `"kimi"` and `"antigravity"`. Kimi Code remains exposed as `pkgs.kimi-code` by its upstream flake overlay and runs with `kimi`. Its host-specific age payload is decrypted from the private input at user login and atomically installed as `~/.kimi-code/config.toml` with mode `0600`; the plaintext API key never enters the Nix store. The old singular `modules.ai.client` option remains as a deprecated compatibility interface and overrides `clients` when explicitly set.

Google Antigravity CLI is packaged locally as `pkgs.google-antigravity-cli` from Google's official Linux release archive, pinned to version 1.2.6 and verified by the published SHA-512 digest. Run it with:

```sh
agy
```

On first launch, `agy` uses the Linux Secret Service over D-Bus when an existing Antigravity token is available; otherwise it opens the default browser for Google sign-in. An SSH session receives a URL and authorization code instead. The Nix wrapper sets `AGY_CLI_DISABLE_AUTO_UPDATE=true`, because immutable Nix store binaries must be upgraded by changing the package version and hashes in this repository rather than with `agy update`.[25] [26]

No Google credential is written into the Nix store. For optional headless API-key authentication, set `modelProvider` to `"gemini"` in `~/.gemini/antigravity-cli/settings.json` and provide `GEMINI_API_KEY` through a secret-bearing runtime environment; defining the variable alone does not activate API-key mode. Do not commit that key to this repository. Antigravity is an agent capable of editing files and executing commands, so review its permission prompts and Google's terms and interaction-data policy before use.[25] [27]

A separate `modules.ide` module manages full GUI IDEs as a distinct concern from AI coding clients. The distinction matters because IDEs are graphical applications with their own update cadences, while `modules.ai.clients` groups command-line coding agents that share a tighter integration contract. The two namespaces are independent: enabling `modules.ai` and `modules.ide` together is normal; either can be omitted without affecting the other. `smunix` enables both, selecting `antigravity` and `zed` under `modules.ide`.

Zed is installed through `modules.ide.ides` alongside Antigravity IDE. Its home-manager program configuration—`base_keymap = "VSCode"`, `vim_mode`, and font sizes scaled by the compact-font factor—is still declared through `modules.desktop.editors.zed.enable`; that option controls the program settings while `modules.ide` controls the installed package. Both options must be enabled together for a fully configured Zed.

Google Antigravity IDE is packaged locally as `pkgs.google-antigravity-ide` from Google's official Linux release archive, pinned to version 2.5.5 and verified by the published SHA-512 digest. It is a standalone Electron application derived from VS Code and ships with its own Chromium runtime. The Nix derivation uses `autoPatchelfHook` to satisfy the Chromium shared-library dependencies declaratively and installs a `.desktop` entry and application icon. Two command names are available after installation:

```sh
agy-ide        # short alias, consistent with the agy CLI naming convention
antigravity-ide  # explicit form; both invoke the same binary
```

`agy-ide` is the `mainProgram`, so `nix run .#google-antigravity-ide` and `nix shell` resolve to it. Both wrappers set `ELECTRON_OZONE_PLATFORM_HINT=auto` so the IDE selects Wayland rendering automatically when running under Niri or Plasma Wayland, and falls back to XWayland otherwise. The Niri workspace table routes `antigravity-ide` to the `programming` workspace alongside `zeditor`.[28]

The `modules.ide.ides` option accepts a list so multiple IDEs can coexist. The current recognized values are `"antigravity"` and `"zed"`. A deprecated single-selection shim `modules.ide.ide` is available for forward compatibility but emits a warning; use `modules.ide.ides` instead. An assertion rejects enabling `modules.ide` with an empty `ides` list.

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
| `Super+4` | `programming` | Zed (`zeditor`), Antigravity IDE (`agy-ide`) |
| `Super+5` | `explorers` | Dolphin |
| `Super+6` | `chats` | Discord, Signal Desktop, Zoom |
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

Evaluate, build, or deploy the remote OVH Cloud VPS (`vps-73025e99`):

```sh
nix eval .#nixosConfigurations.vps-73025e99.config.system.build.toplevel.drvPath
nix build .#nixosConfigurations.vps-73025e99.config.system.build.toplevel
deploy .#vps-73025e99
```

The host’s filesystem, encryption, swap, and CPU declarations remain isolated in `hosts/smunix/hardware.nix` and `hosts/vps-73025e99/hardware.nix`. Keep those values aligned with each machine’s hardware configuration.

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

The problem with developing eBPF directly on the workstation is that loading test programs requires elevated kernel access and a failed program can disturb host networking or security hooks. `modules.develop.aya` therefore installs the build and inspection tools on `smunix`, while `ebpf-vm` runs programs in a disposable NixOS VM with the required BPF kernel features. Aya’s tier-three BPF target still relies on Cargo’s unstable `build-std` support.[11] The host nevertheless uses the same stable rustc 1.98.1 binary everywhere: only the `aya-cargo` and `aya-rustc` wrappers scope `RUSTC_BOOTSTRAP=1` so Aya can compile `core` for BPF without installing a second nightly compiler. The `aya-tool` command generates Rust bindings for selected Linux kernel types and requires both `bpftool` and `bindgen`; the packaged wrapper supplies those dependencies automatically.[13]

The Rust module is the single owner of the host toolchain. `modules.develop.rust.channel = "stable"` and `version = "1.98.1"` resolve one rust-overlay toolchain containing Cargo, rustc, rustfmt, Clippy, rust-analyzer, and `rust-src`. The same policy also builds the repository’s Rust utilities, including `aya-tool`, Dioxus CLI, and the exact wasm-bindgen CLI. Aya and Dioxus reuse the read-only resolved `toolchain`; neither feature owns a second host compiler version. The deprecated `nightlyVersion` option remains as a temporary compatibility alias for other hosts, but `smunix` no longer selects it.

| Component | Selected implementation |
|---|---|
| Rust toolchain | Shared stable `modules.develop.rust.version = "1.98.1"`, with `rust-src`, rustfmt, Clippy, and rust-analyzer; the same stable compiler and `bpf-linker` are installed inside `ebpf-vm` |
| BPF linker | Official static `bpf-linker` 0.11.1 x86_64-musl artifact with the supplied fixed hash |
| Build command | `aya-cargo`, with `ebpf-cargo` as a shell alias |
| Kernel bindings | `aya-tool` with wrapped `bpftool`, `bindgen`, and libclang dependencies; installed on both the host and VM |
| Inspection and tracing tools | `bpftool`, `bpftrace` 0.25.1, `pahole`, `llvm-objdump`, and `tcpdump`; installed on both the host and VM |
| Virtualization access | The primary user is added to `kvm`; log out and back in after activation |
| Guest resources | Four virtual CPUs and 4096 MiB RAM |
| Shared source | The requested host directory is mounted at `/host` through VirtFS/9P[12] |
| SSH access | Host loopback `127.0.0.1:2222` forwards to guest TCP port 22; only `dev` may log in, with automatic host public-key authorization and `dev` password fallback |

Plain `cargo`, `rustc`, `rustfmt`, `clippy`, and `rust-analyzer` use stable 1.98.1 throughout the host. `aya-cargo` is the eBPF-specific wrapper: it selects that same stable toolchain explicitly, exports its Rust source tree, enables `RUSTC_BOOTSTRAP=1` only for Aya’s unstable BPF `build-std` operation, and puts the exact `bpf-linker` first on `PATH`:

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

The VM enables `BPF_SYSCALL`, JIT compilation, BTF kernel metadata, BPF LSM support, cgroups, namespaces, seccomp filtering, and audit support. It explicitly places `bpf` in the active LSM order. The guest includes stable Rust 1.98.1 with `rust-src`, `bpf-linker`, `aya-tool`, `bpftool`, `bpftrace`, `pahole`, `iproute2`, and `tcpdump`. Because the entire guest exists specifically for Aya development, it scopes `RUSTC_BOOTSTRAP=1` to the VM environment so the tier-three BPF target can use `build-std` without a nightly rustc binary. **The `dev`/`dev` credentials, passwordless sudo, and root console autologin are intentionally unsafe and belong only to the disposable laboratory VM; never copy them to a persistent host or production image.**

Inside the VM, inspect the environment with:

```sh
cd /host
uname -a
bpftool feature probe kernel
bpftool btf show
cat /sys/kernel/security/lsm
```

The first VM invocation may build or download a substantial NixOS and QEMU closure. Later launches reuse the Nix store and are faster. Stop the VM normally with `poweroff` from the guest.

## Dioxus desktop, web, and Android development

`modules.develop.dioxus` installs the pinned Dioxus **0.8-series** `dx` CLI and integrates it with the shared stable Rust 1.98.1 toolchain. The newest published 0.8 CLI is currently the prerelease `0.8.0-alpha.1`, while 0.7.10 remains the maximum stable release; this configuration deliberately selects the requested 0.8 series and pins its crate source and lockfile.[18] Linux desktop applications additionally receive GTK3, WebKitGTK 4.1, DBus, xdotool, OpenSSL, app-indicator, librsvg, Clang, LLD, Make, and pkg-config support required by Dioxus desktop builds.[15] The generated wrapper computes the full propagated GTK/WebKit dependency closure and derives its GLib/GIO/GObject, Pango, ATK, Cairo, GDK Pixbuf, pkg-config, data, GIO-module, and runtime-library paths. This avoids both a fragile list of direct `.pc` paths and dependence on a later fixup hook that may not run for `symlinkJoin`.

| Component | Selected implementation |
|---|---|
| Dioxus CLI | Reproducibly packaged `dioxus-cli` 0.8.0-alpha.1, exposed as `dx`; automatic tool downloads and telemetry are disabled |
| Rust toolchain | Shared stable Rust 1.98.1, satisfying the CLI’s Rust 1.93 minimum and extended declaratively with WebAssembly plus all four Android targets |
| Web | `wasm32-unknown-unknown`, exact `wasm-bindgen-cli` 0.2.128, and Binaryen `wasm-opt` |
| HTTPS development server | `dioxus-serve` binds the backend to `127.0.0.1:8080`; a user-owned Caddy service discovers and binds the current `wlp0s20f3` IPv4 address after Wi-Fi connects while the raw Dioxus port remains closed |
| Android Studio | 2025.3.4.7 |
| Android platform and Build Tools | API 35 and Build Tools 35.0.0 |
| NDK and CMake | NDK 27.2.12479018 and CMake 3.22.1 |
| Emulator | Android emulator 36.5.11 with a Google APIs API-35 x86_64 system image |
| Java | OpenJDK 17 |
| Hardware acceleration | The primary user belongs to `kvm`; log out and back in after activation |

Without `wasm32-unknown-unknown` in the active Rust sysroot, `dx serve --platform web` attempts `rustup target add`. Nix-managed hosts do not install or mutate toolchains through rustup, so that fallback fails with `No such file or directory`. Enabling `modules.develop.dioxus.web` adds the target to the shared rust-overlay toolchain and installs `wasm-opt` declaratively.

The `wasm-bindgen` crate embedded in an application and the external `wasm-bindgen` command must use the same schema version. The Damabase application requires 0.2.128, so this repository packages that exact crates.io release and selects it through `modules.develop.dioxus.web.wasmBindgenCliPackage`.[19] The module-generated `dx` wrapper prepends the selected package to `PATH`, ensuring it wins over older profile or Cargo-installed executables. Override that package option deliberately when a future project lockfile requires another version.

Verify web tooling after rebuilding:

```sh
rustc --print target-libdir --target wasm32-unknown-unknown
wasm-bindgen --version  # expected: wasm-bindgen 0.2.128
wasm-opt --version
```

Run the web application with hot reload on the local machine:

```sh
cd ~/Projects/demos/damabase/project
dx serve --platform web -p damabase-app
```

### Caddy HTTPS for the Dioxus development server

The `smunix` host runs Caddy as the only LAN-facing entry point. The `dioxus-serve` helper passes the configured loopback address and port before all project arguments, so Dioxus listens on plain HTTP at `127.0.0.1:8080` and is not directly reachable from another machine:

```sh
cd ~/Projects/demos/damabase/project
dioxus-serve --platform web -p damabase-app
```

`dioxus-serve-lan` remains as a compatibility alias, but it uses the same configured loopback endpoint. For `smunix`, either helper is equivalent to `dx serve --addr 127.0.0.1 --port 8080 ...`.

Caddy runs as `smunix` through `dioxus-caddy.service`, a systemd **user service with no boot target**. A NetworkManager dispatcher reacts only to `wlp0s20f3`: `up`, `dhcp4-change`, and `reapply` events obtain the interface's first global IPv4 address and restart the user service; `pre-down` and `down` stop it. A boot-time reconciliation handles Wi-Fi that was already active while the new system generation was activated. Declarative lingering keeps the user manager available without making Caddy an unconditional login or boot service.[22] [23]

The site address and `bind` target are both filled from the detected address before Caddy parses its configuration. Conceptually, a Wi-Fi address such as `192.168.1.50` produces this runtime Caddyfile:

```caddyfile
{
  skip_install_trust
}

http://192.168.1.50 {
  bind 192.168.1.50
  redir https://192.168.1.50{uri}
}

192.168.1.50 {
  bind 192.168.1.50
  tls internal
  reverse_proxy 127.0.0.1:8080

  header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
    Referrer-Policy "strict-origin-when-cross-origin"
  }

  encode zstd gzip
}
```

Caddy handles the Dioxus hot-reload WebSocket automatically. Explicit HTTP and HTTPS site blocks bind both listeners to the detected Wi-Fi address; relying only on Caddy's automatically generated redirect listener would bind HTTP on every interface. The firewall permits TCP 80 for HTTP-to-HTTPS redirects, TCP 443 for HTTPS, and UDP 443 for HTTP/3 **only on `wlp0s20f3`**. TCP 8080 stays closed, and a module assertion rejects enabling Caddy while Dioxus listens on a non-loopback address or its raw port is open. A root-owned wrapper executable only by the existing `wheel` group grants `CAP_NET_BIND_SERVICE`, allowing the unprivileged Caddy process to bind ports below 1024 without running the service as root. The user unit deliberately avoids filesystem-namespace directives such as `PrivateTmp` and `ProtectSystem`: systemd implements those directives for user units with a private user namespace, where file capabilities cannot grant authority over low ports in the host's network namespace.[17] [20] [24]

After rebuilding, connect Wi-Fi, start Dioxus, and inspect both services:

```sh
systemctl --user status dioxus-caddy
systemctl --user cat dioxus-caddy
dioxus-caddy-address
ip -4 -o address show dev wlp0s20f3 scope global
ss -ltnp | grep -E ':(80|443|8080)\\b'
journalctl --user -b -u dioxus-caddy
journalctl -b -u NetworkManager-dispatcher -u dioxus-caddy-network-sync
```

`dioxus-caddy-address` prints the current URL, for example `https://192.168.1.50`. Caddy's internal CA is private to this user service, so every client must trust its root certificate or the browser will correctly report an unknown issuer. The generated configuration uses `skip_install_trust` because an unprivileged background service cannot install a system trust anchor noninteractively. Once the user service has started, install the root deliberately in the host's trust stores and export a public copy:

```sh
sudo caddy trust
cp "$HOME/.local/share/caddy/pki/authorities/local/root.crt" \
  "$HOME/caddy-local-root.crt"
chmod 0644 "$HOME/caddy-local-root.crt"
curl --cacert "$HOME/caddy-local-root.crt" "$(dioxus-caddy-address)"
```

Transfer only `caddy-local-root.crt` to each trusted LAN client and import it as a trusted certificate authority. Never copy anything else from Caddy's PKI directory: its private root and intermediate keys must remain on `smunix`. Trusting the root lets that Caddy installation authenticate any name or address for which it issues a certificate, so install it only on devices you control.[20] [21]

When DHCP changes the Wi-Fi address, NetworkManager restarts Caddy with the new bind and certificate address. The internal root CA remains the same, so already trusted clients do not need a new root, but they must browse to the newly reported URL. Disconnecting `wlp0s20f3` stops Caddy even if another interface remains online.

For a public DNS name later, set `hostName` to that name and `tlsMode = "public"`; Caddy then omits `tls internal` and obtains and renews a public certificate automatically while continuing to bind the current Wi-Fi address. Point the DNS A/AAAA records at the server and forward public TCP 80 and 443 before enabling that mode. An optional `caddy.acmeEmail` configures the ACME account email. Dynamic address mode deliberately accepts only internal TLS; public TLS requires a fixed DNS `hostName`. Do not expose Dioxus itself or use the development server as a hardened production application server.[20]

Do **not** run `rustup target add wasm32-unknown-unknown`; change `modules.develop.dioxus.web` or the shared Rust target list instead.

After rebuilding, inspect the installation:

```sh
dx --version
dx doctor
printf '%s\n' "$ANDROID_HOME" "$ANDROID_NDK_HOME" "$JAVA_HOME"
adb version
emulator -version
```

To run a Dioxus application immediately as a native desktop application with hot reloading:

```sh
cd ~/src/my-dioxus-app
dx serve --platform desktop
```

The Dioxus 0.8 CLI also provides the shorthand form.[17]

```sh
dx serve --desktop
```

If a Rust `*-sys` crate reports missing metadata such as `dbus-1.pc`, `gio-2.0.pc`, `gobject-2.0.pc`, `pango.pc`, or `atk.pc`, inspect the regenerated wrapper after rebuilding:

```sh
DX_WRAPPER="$(readlink -f "$(command -v dx)")"
grep 'PKG_CONFIG_PATH' "$DX_WRAPPER"
```

The Dioxus module closes over both direct and propagated desktop dependencies, derives `PKG_CONFIG_PATH`, `LD_LIBRARY_PATH`, `XDG_DATA_DIRS`, and `GIO_EXTRA_MODULES`, and writes those values into the `dx` wrapper during `postBuild`. Every Cargo process started by `dx` therefore inherits the same deterministic environment. A plain `pkg-config` invocation outside `dx` intentionally does not inherit that scoped environment.

Native desktop links can report `unable to find library -lclang`, `-lxdo`, or another `-l<name>` even when the runtime library is present, because linkers need explicit compile-time search directories. `modules.develop.dioxus.desktop.libclangPackage` selects LLVM libclang, while the generated wrapper builds `LIBRARY_PATH` from every runtime and development `lib` directory in the propagated GTK/WebKit desktop closure. The pinned Dioxus 0.8 package carries a focused Linux patch (`pkgs/patches/dioxus-cli-0_8-library-path.patch`) that inspects `LIBRARY_PATH` and appends every directory as a deduplicated `-L<path>` flag to both incremental thin-linking and full fat-binary linking commands. Shell completions for Bash, Fish, and Zsh are generated via file redirection during `postInstall` with cross-compilation guards.

The standalone `dioxus-cli_0_8` derivation packages default fallback web tools (`esbuild`, `binaryen`, and `wasm-bindgen-cli_0_2_128`). When `modules.develop.dioxus` is enabled, its `symlinkJoin` wrapper prepends any host-configured web tool overrides (such as `cfg.web.wasmBindgenCliPackage` and `cfg.web.wasmOptPackage`) to `PATH`, allowing project-specific tooling overrides without requiring a full recompilation of `dioxus-cli`.

```sh
DX_WRAPPER="$(readlink -f "$(command -v dx)")"
grep -E 'LIBCLANG_PATH|LIBRARY_PATH' "$DX_WRAPPER"
```

Plain Cargo remains an alternative without the same integrated development server:

```sh
cargo run
```

Android support is fully declarative. Do **not** run `rustup target add`: the Rust module already includes `aarch64-linux-android`, `armv7-linux-androideabi`, `i686-linux-android`, and `x86_64-linux-android` in the resolved stable 1.98.1 toolchain, matching the targets recommended by the Dioxus mobile guide.[16]

Android Studio and command-line tools use these generated paths:

```text
ANDROID_HOME=/nix/store/...-androidsdk/libexec/android-sdk
ANDROID_SDK_ROOT=$ANDROID_HOME
ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.2.12479018
NDK_HOME=$ANDROID_NDK_HOME
JAVA_HOME=/nix/store/...-openjdk-17.../lib/openjdk
```

The SDK and NDK are read-only Nix store content. Use Android Studio for editing, device management, and AVD management, but change SDK component versions through `modules.develop.dioxus.android` rather than asking Studio to mutate the SDK. AVD definitions and emulator data remain writable in the user profile.

Create and start the included emulator image:

```sh
avdmanager create avd \
  --force \
  --name Pixel_API_35 \
  --package 'system-images;android-35;google_apis;x86_64'

emulator -avd Pixel_API_35 -netdelay none -netspeed full
adb devices
```

With an emulator running, serve the Android application:

```sh
dx serve --android
```

Dioxus also accepts the explicit platform form where supported by the project and CLI command:

```sh
dx serve --platform android
```

The first rebuild is large because Android Studio, the SDK, NDK, emulator, system image, WebKitGTK, Binaryen, and five Rust target libraries enter the system closure. Subsequent builds reuse the Nix store.

## Remote VPS server (`vps-73025e99`)

The repository defines the remote cloud host `vps-73025e99` (`vps-73025e99.vps.ovh.ca`), an OVH Cloud VPS instance running NixOS 26.05 (Yarara) on Linux 6.18. It serves the Hodari Accounting web application over HTTPS at `https://accounting.hodari.ca`.

### Disk layout and declarative partitioning (Disko)

Storage on `/dev/sda` is managed declaratively via [Disko](https://github.com/nix-community/disko) (`hosts/vps-73025e99/disko.nix`):

| Partition | Type | Size | Mount / Flags | Purpose |
|---|---|---|---|---|
| `boot` | `EF02` | 1 MiB | Priority 1 | BIOS Boot Partition for legacy MBR booting on a GPT table |
| `ESP` | `EF00` | 1 GiB | `/boot` (`vfat`, `umask=0077`) | EFI System Partition for UEFI booting |
| `swap` | `swap` | 4 GiB | `discardPolicy = "both"` | Swap partition with TRIM enabled |
| `root` | Linux filesystem | 100% | `/` (`ext4`) | NixOS root filesystem |

### Bootloader: Hybrid UEFI and BIOS GRUB

To accommodate virtualization across cloud VPS providers, `hosts/vps-73025e99/default.nix` configures a hybrid bootloader using GRUB:

```nix
boot.loader.systemd-boot.enable = false;
boot.loader.efi.canTouchEfiVariables = false;
boot.loader.grub = {
  enable = true;
  efiSupport = true;
  efiInstallAsRemovable = true;
  device = "/dev/sda";
};
```

`canTouchEfiVariables = false` prevents attempts to modify non-volatile EFI variables, which virtualized VPS firmware frequently disallows. `efiInstallAsRemovable = true` installs GRUB to `/boot/EFI/BOOT/BOOTX64.EFI`, allowing firmware autodiscovery without NVRAM entries, while `device = "/dev/sda"` writes MBR code to the disk's first sector paired with the 1MB `EF02` BIOS boot partition.

### Secret management and GitLab deploy key (SOPS-Nix)

Secrets are decrypted using [sops-nix](https://github.com/Mic92/sops-nix) with the host's existing SSH Ed25519 host key (`/etc/ssh/ssh_host_ed25519_key`) as the age recipient:

- Decrypts `${inputs.secrets}/hosts/vps-73025e99/secrets.yaml`.
- Materializes the GitLab deploy key to `/home/smunix/.ssh/id_gitlab_deploy` with permissions `0400` owned by `smunix`.
- Configures OpenSSH client options so `git` commands accessing `gitlab.com` automatically use this key.

### Services: Hodari Accounting and Caddy Ingress

1. **Hodari Accounting Server (`modules.services.hodari-accounting`)**:
   - Packaged from `inputs.hodari-accounting` (`git+ssh://git@gitlab.com/hodari-smunix/hodari-accounting.git`).
   - Runs as a hardened systemd unit: `DynamicUser = true`, `ProtectSystem = "strict"`, `ProtectHome = true`, `PrivateTmp = true`, `NoNewPrivileges = true`, and `RestrictRealtime = true`.
   - Listens on loopback port `127.0.0.1:8080`. The firewall port remains closed (`openFirewall = false`).

2. **Caddy Reverse Proxy (`services.caddy`)**:
   - Terminates public HTTP (port 80) and HTTPS (port 443) traffic with automatic Let's Encrypt certificates.
   - Proxies `accounting.hodari.ca` to `127.0.0.1:8080` with zstd/gzip compression, HSTS, `nosniff`, and `SAMEORIGIN` headers.
   - Permanently redirects all requests from the VPS host domain `vps-73025e99.vps.ovh.ca` to `https://accounting.hodari.ca{uri}`.

### Dynamic Login Banner (`modules.services.motd`)

Interactive SSH logins display a dynamic, high-performance system dashboard generated with `pkgs.rust-motd`:

- **Banner Information**: NixOS release, kernel version, NixOS manual link, system generation, uptime, 1/5/15-minute load averages, root filesystem usage bar, memory & swap gauges, public IPv4 and global IPv6 on `ens3`, and live statuses of `caddy` and `hodari-accounting`.
- **Interactive Guard**: Executed through `environment.interactiveShellInit` with `[ -n "$SSH_CONNECTION" ] && [ -t 1 ] && [ -z "$_MOTD_SHOWN" ]` so that non-interactive remote commands (`nix copy`, `scp`, `rsync`, batch scripts) remain unpolluted, and nested shells or `tmux` sessions avoid duplicate banners.
- **Latency**: Benchmarked at under 70 milliseconds on the VPS.

### Remote deployment

Deploy updates to the VPS using `deploy-rs`:

```sh
deploy .#vps-73025e99
```

Or via direct Nix closure copy and activation:

```sh
nix build .#nixosConfigurations.vps-73025e99.config.system.build.toplevel -o result-vps
nix copy --to ssh://vps-73025e99.vps.ovh.ca ./result-vps
ssh vps-73025e99.vps.ovh.ca "sudo ./result-vps/bin/switch-to-configuration switch"
rm -f ./result-vps
```



[11]: https://aya-rs.dev/book/start/development.html "Aya development environment"
[12]: https://nixos.org/manual/nixos/stable/#sec-qemu-vm "NixOS QEMU virtual machines"
[13]: https://aya-rs.dev/book/aya/aya-tool.html "Using aya-tool"
[14]: https://bpftrace.org/docs/release_025/docs "bpftrace 0.25 documentation"
[15]: https://dioxuslabs.com/learn/0.7/getting_started/ "Dioxus 0.7 getting started and Linux desktop dependencies"
[16]: https://dioxuslabs.com/learn/0.7/guides/platforms/mobile/ "Dioxus 0.7 mobile development guide"
[17]: https://dioxuslabs.com/learn/0.7/tutorial/bundle/ "Dioxus desktop and Android serving"
[18]: https://crates.io/crates/dioxus-cli/0.8.0-alpha.1 "dioxus-cli 0.8.0-alpha.1 release metadata"
[19]: https://crates.io/crates/wasm-bindgen-cli/0.2.128 "wasm-bindgen-cli 0.2.128 release metadata"
[20]: https://caddyserver.com/docs/automatic-https "Caddy automatic and local HTTPS"
[21]: https://caddyserver.com/docs/command-line#caddy-trust "Caddy local CA trust command"
[22]: https://networkmanager.dev/docs/api/latest/NetworkManager-dispatcher.html "NetworkManager dispatcher events and interface arguments"
[23]: https://www.freedesktop.org/software/systemd/man/latest/loginctl.html "systemd user lingering"
[24]: https://www.freedesktop.org/software/systemd/man/255/systemd.exec.html "systemd user-service namespace and capability semantics"
[25]: https://antigravity.google/docs/cli/install/ "Google Antigravity CLI installation and authentication"
[26]: https://antigravity.google/docs/cli/troubleshooting/ "Google Antigravity CLI updater and keyring troubleshooting"
[27]: https://antigravity.google/terms "Google Antigravity terms of service"
[28]: https://antigravity.google/product/antigravity-ide/ "Google Antigravity standalone IDE"
