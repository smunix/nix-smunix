# Custom module inventory

This document summarizes the reusable modules and composition helpers in this configuration. The `smunix` host selects features through `hosts/smunix/default.nix`; modules are discovered recursively, so adding a Nix file below `modules/nixos/` or `modules/home-manager/` makes it available without a central import list.

## System and user foundation

| Component | Interface or location | Responsibility |
|---|---|---|
| Shared user options | `modules/nixos/options.nix` | Defines the primary user’s name, display name, email, home directory, groups, and user packages. It also projects these values into the NixOS account and integrated Home Manager account. |
| Shared NixOS base | `default.nix` | Applies host-wide defaults, imports reusable NixOS modules, and integrates Home Manager into the NixOS configuration. |
| Base Home Manager profile | `modules/home-manager/base.nix` | Enables the shared Home Manager identity, state version, and user-environment baseline. |
| General Home Manager packages | `modules/home-manager/packages.nix` | Installs the non-feature-specific user package profile. |
| Home Manager module aggregate | `modules/home-manager/default.nix` | Recursively imports the Home Manager feature tree for both NixOS-integrated and exported use. |
| Host manifest | `hosts/smunix/default.nix` | Selects the capabilities enabled for the `smunix` machine. |
| Host hardware | `hosts/smunix/hardware.nix` | Keeps generated, machine-specific boot, filesystem, CPU, and encrypted-swap declarations separate from reusable policy. |

## Desktop, programs, and workstation features

| Module | Option | Responsibility |
|---|---|---|
| Plasma | `modules.desktop.plasma.enable` | Enables Plasma 6 and SDDM, preserving a standard graphical login and desktop session. |
| Niri and Noctalia | `modules.desktop.niri.enable` | Adds an SDDM-selectable Niri session with Noctalia’s desktop shell, seven persistent named workspaces, application-to-workspace rules, a `dumpster` fallback for unmatched applications, and maximized opening for normal application windows. It also owns the stable compositor, Xwayland Satellite, portals, keyring, desktop helpers, fonts, icons, cursor, and managed KDL/TOML configuration. |
| Terminal selector | `modules.desktop.terminal.default` | Selects Ghostty or WezTerm and exports `TERMINAL` through system and Home Manager session environments. |
| Ghostty | `modules.desktop.terminal.ghostty.enable` | Installs Ghostty with the reference-style Maple Mono font, translucent dark palette, and Nushell startup command. |
| WezTerm | `modules.desktop.terminal.wezterm.enable` | Installs WezTerm independently as an alternative and starts Nushell by default. |
| Brave | `modules.desktop.browsers.brave.enable` | Enables Brave through Home Manager’s Chromium-compatible browser support. |
| Discord | `modules.desktop.chats.discord.enable` | Installs the Discord desktop chat client through the integrated Home Manager profile. |
| Signal | `modules.desktop.chats.signal.enable` | Installs Signal Desktop through the integrated Home Manager profile. |
| Compact fonts | `modules.desktop.fonts.compact.enable` | Applies the 15% smaller GTK, KDE, and X11 font baselines consumed by the desktop and application modules. |
| TDF | `modules.desktop.viewers.tdf.enable` | Installs TDF, a terminal-based PDF viewer that runs inside the configured terminal workspace. |
| Zathura | `modules.desktop.viewers.zathura.enable` | Installs Zathura for lightweight graphical PDF and document viewing. |
| MPV | `modules.desktop.viewers.mpv.enable` | Installs MPV for graphical audio and video playback. |
| Editor selector | `modules.desktop.editors.default` | Sets `EDITOR` and `VISUAL` to the selected editor in both system and Home Manager session environments. |
| Helix | `modules.desktop.editors.helix.enable` | Installs and configures Helix, including relative line numbers and automatic formatting. |
| Vim | `modules.desktop.editors.vim.enable` | Installs Vim through Home Manager. |
| Zed | `modules.desktop.editors.zed.enable` | Installs and configures Zed with Vim mode and Nix language support. |
| Firefox | `modules.programs.firefox.enable` | Enables Firefox. |
| Search utilities | `modules.programs.cli.search.enable` | Installs `ack`, `ripgrep`, and `fd` as a focused text and filesystem search toolset. |
| System utilities | `modules.programs.cli.system.enable` | Installs `coreutils` and `pciutils` as foundational command-line inspection tools. |
| Waybar | `modules.programs.waybar.enable` | Enables Waybar as a standalone program feature for desktop environments that use it. |

## Development, shell, and version-control features

| Module | Option | Responsibility |
|---|---|---|
| C and C++ | `modules.develop.cc.enable` | Provides GCC, Clang, CMake, Make, GDB, pkg-config, and Clang tooling. |
| Rust | `modules.develop.rust.enable` | Provides Rust, Cargo, rustfmt, Clippy, and rust-analyzer. |
| Haskell | `modules.develop.haskell.enable` | Provides GHC, Cabal, Haskell Language Server, and HLint. |
| Python | `modules.develop.python.enable` | Provides Python 3, uv, Ruff, and Pyright. |
| Typst | `modules.develop.typst.enable` | Provides Typst, the Tinymist language server, and Typstyle formatter. |
| Quarto | `modules.develop.quarto.enable` | Provides Quarto for scientific and technical publishing workflows. |
| Nushell selector | `modules.shell.default = "nushell"` | Adds Nushell as the primary user’s valid login shell and exports it through system, Home Manager session, and Nushell environments. |
| Starship | `modules.shell.starship.enable` | Enables the Starship prompt for Nushell and Bash, including OS and Kubernetes context indicators. |
| Zellij | `modules.shell.zellij.enable` | Installs and configures Zellij as a tmux alternative, with Nushell as its pane shell and Helix as its scrollback editor. |
| Git | `modules.vcs.git.enable` | Installs Git Full and declares reusable Git aliases and settings. |
| Jujutsu | `modules.vcs.jujutsu.enable` | Installs Jujutsu and generates its managed author identity from `user.description` and `user.email`; assertions prevent an empty identity. |

## System services and security

| Module | Option | Responsibility |
|---|---|---|
| NetworkManager | `modules.networking.networkManager.enable` | Enables NetworkManager-based networking. |
| PipeWire | `modules.hardware.pipewire.enable` | Enables PipeWire, WirePlumber, and ALSA/PulseAudio compatibility. |
| Printing | `modules.hardware.printing.enable` | Enables CUPS printing. |
| Power selector | `modules.hardware.power.backend` | Selects `upower` or `tlp`; TLP remains the policy engine while retaining UPower for desktop battery telemetry. |
| TLP | `modules.hardware.power.tlp.enable` | Disables the conflicting power-profiles daemon, enables TLP and its profile compatibility service, configures AC/battery CPU policies, runtime PCI power management, and configurable BAT0 charge thresholds. |
| UPower | `modules.hardware.power.upower.enable` | Provides percentage-based battery telemetry, warning levels, desktop integration, and critical-power handling. |
| Lid actions | `modules.hardware.power.lid.enable` | Configures logind actions for lid closure on battery, external power, and while docked. |
| NVIDIA PRIME | `modules.hardware.nvidia.enable` | Enables NVIDIA graphics, modesetting, fine-grained runtime power management, the open kernel module, settings tools, and PRIME offload using required host-specific PCI bus IDs. |
| Passwordless sudo | `modules.security.passwordlessSudo.enable` | Grants the configured primary user a `NOPASSWD` sudo rule without changing the password requirement for other wheel users; retained as an opt-in feature but disabled on `smunix`. |
| YubiKey U2F | `modules.security.yubikey.enable` | Enables passwordless PAM authentication with password fallback, deploys a central private-input mapping, installs hardware support, and optionally locks sessions when a Yubico USB device is removed. |

## Flake composition and extension points

| Component | Location | Responsibility |
|---|---|---|
| flake-parts entry point | `flake.nix` | Declares inputs and delegates output composition to flake-parts. |
| Top-level flake outputs | `parts/flake.nix` | Exports the helper library, overlays, recursive NixOS and Home Manager module trees, and discovered NixOS hosts. |
| Per-system outputs | `parts/per-system.nix` | Defines packages and the Alejandra formatter for supported systems. |
| Private source input | `inputs.secrets` | Supplies host-specific U2F mappings and future encrypted payloads as a pinned non-flake input. |
| Discovery helpers | `lib/attrs.nix`, `lib/modules.nix`, `lib/nixos.nix` | Provide attribute helpers, filesystem-based module discovery, and automatic host construction. |
| Custom package overlay | `overlays/additions.nix` | Extension point for locally packaged additions. |
| Package modification overlay | `overlays/modifications.nix` | Extension point for package overrides. |
| Unstable package overlay | `overlays/unstable-packages.nix` | Exposes the pinned unstable package set under the configured overlay. |
| Custom package set | `pkgs/default.nix` | Extension point for packages exported by this flake. |

## Feature selection

The `smunix` manifest enables Plasma and the Niri/Noctalia desktop, NetworkManager, PipeWire, printing, TLP with UPower telemetry, suspend-on-lid-close behavior, NVIDIA PRIME offload with host-specific PCI IDs, the search and system utility groups, the language toolchains including Typst, Nushell, Starship, Zellij, Ghostty as the default terminal, WezTerm as an alternative, Brave, Firefox, Discord, Signal, Git, Jujutsu, Helix, Vim, Zed, the compact-font policy, YubiKey U2F authentication with password fallback, and the shared Home Manager base/package profiles. Niri additionally supplies XTerm, Okular, Evince, and Dolphin for its routed workspaces. The separate TDF, Zathura, and MPV viewer modules are enabled for terminal and graphical document or media viewing. An Xpdf routing rule is present, but the pinned insecure Xpdf package is intentionally not installed. The standalone Waybar module remains reusable but is not selected because Noctalia owns Niri’s bar.
