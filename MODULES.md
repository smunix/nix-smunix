# Custom module inventory

This document summarizes the reusable modules and composition helpers in this configuration. The `smunix` host selects features through `hosts/smunix/default.nix`; modules are discovered recursively, so adding a Nix file below `modules/nixos/` or `modules/home-manager/` makes it available without a central import list.

## System and user foundation

| Component | Interface or location | Responsibility |
|---|---|---|
| Shared user options | `modules/nixos/options.nix` | Defines the primary user’s name, display name, email, home directory, groups, and user packages. It also projects these values into the NixOS account and integrated Home Manager account. |
| Shared NixOS base | `default.nix` | Applies host-wide defaults, imports reusable NixOS modules, integrates Home Manager, and backs up conflicting user files with collision-resistant UTC timestamps. |
| Base Home Manager profile | `modules/home-manager/base.nix` | Enables the shared Home Manager identity, state version, and user-environment baseline. |
| General Home Manager packages | `modules/home-manager/packages.nix` | Installs the non-feature-specific user package profile. |
| Home Manager module aggregate | `modules/home-manager/default.nix` | Recursively imports the Home Manager feature tree for both NixOS-integrated and exported use. |
| Host manifest | `hosts/smunix/default.nix` | Selects the capabilities enabled for the `smunix` machine. |
| Host hardware | `hosts/smunix/hardware.nix` | Keeps generated, machine-specific boot, filesystem, CPU, and encrypted-swap declarations separate from reusable policy. |

## Desktop, programs, and workstation features

| Module | Option | Responsibility |
|---|---|---|
| Plasma | `modules.desktop.plasma.enable` | Enables Plasma 6 and SDDM with configurable automatic locking, an immediate authentication requirement, lock-on-resume behavior, and Plasma’s dedicated `kde-fingerprint` unlock path. |
| Niri and Noctalia | `modules.desktop.niri.enable`, `.packageChannel`, `.monitorLayout.*` | Adds an SDDM-selectable Niri session with selectable stable or unstable compositor and matching Xwayland Satellite packages; configurable Noctalia locking and Niri-only Gammastep; seven persistent named workspaces; application routing; a full-width `dumpster` fallback; widescreen proportions; and tabbed columns. A typed, generated fragment supports the DP-5 portrait-left/eDP-1 HiDPI-right layout, full-width portrait columns, and selectable external or internal ownership of every named workspace. `Mod+O` moves the focused window to the next monitor without changing the opening rules for future windows. |
| Niri Gammastep | `modules.desktop.niri.gammastep.*` | Uses manual coordinates or GeoClue automatic location and fades between configurable day and night color temperatures through Wayland. The GeoClue path requests a fresh NetworkManager scan, runs a bounded location probe, and can fall back to validated coordinates; unused NMEA and modem sources are disabled. Gammastep and the GeoClue agent are bound to `niri.service`, and Niri environment conditions prevent both from running under Plasma. |
| Terminal selector | `modules.desktop.terminal.default` | Selects Ghostty or WezTerm and exports `TERMINAL` through system and Home Manager session environments. |
| Ghostty | `modules.desktop.terminal.ghostty.enable` | Installs Ghostty with the reference-style Maple Mono font, translucent dark palette, and Nushell startup command. |
| WezTerm | `modules.desktop.terminal.wezterm.enable` | Installs WezTerm independently as an alternative and starts Nushell by default. |
| Brave | `modules.desktop.browsers.brave.enable` | Enables Brave through Home Manager’s Chromium-compatible browser support. |
| Discord | `modules.desktop.chats.discord.enable` | Installs the Discord desktop chat client through the integrated Home Manager profile. |
| Signal | `modules.desktop.chats.signal.enable` | Installs Signal Desktop through the integrated Home Manager profile. |
| Compact fonts | `modules.desktop.fonts.compact.enable`, `.reduction` | Derives shared Noctalia, GTK, Qt, KDE, X11, Ghostty, WezTerm, and Zed font scales from a selectable `5`, `10`, `15`, `20`, `25`, `30`, or `35` percent reduction. |
| TDF | `modules.desktop.viewers.tdf.enable` | Installs TDF, a terminal-based PDF viewer that runs inside the configured terminal workspace. |
| Zathura | `modules.desktop.viewers.zathura.enable` | Installs Zathura for lightweight graphical PDF and document viewing. |
| MPV | `modules.desktop.viewers.mpv.enable` | Installs MPV for graphical audio and video playback. |
| Editor selector | `modules.desktop.editors.default` | Sets `EDITOR` and `VISUAL` to the selected editor in both system and Home Manager session environments. |
| Helix | `modules.desktop.editors.helix.enable` | Installs and configures Helix, including relative line numbers and automatic formatting. |
| Vim | `modules.desktop.editors.vim.enable` | Installs Vim through Home Manager. |
| Zed | `modules.desktop.editors.zed.enable` | Installs and configures Zed with Vim mode and Nix language support. |
| Firefox | `modules.programs.firefox.enable` | Enables Firefox. |
| OBSBOT Tail 2 | `modules.hardware.obsbot.*` | Matches the Tail 2 UVC capture interface, creates `/dev/obsbot-tail2`, remaps its DJI Mic 3 input to the stable `obsbot_dji_mic` PipeWire source, temporarily selects that source as default, and starts OBS through a graphical user service. Device, audio, and virtual-camera readiness checks use bounded retries; repeated failures are rate-limited and audio routing is cleaned up automatically. |
| OBS Studio | `modules.programs.obs.enable`, `.ndi.enable`, `.virtualCamera.*` | Installs wrapped OBS Studio and `v4l-utils`, optionally adds DistroAV/NDI, configures `/dev/video10`, and grants `video` and `render` access. Tail 2-specific behavior lives exclusively in the separate OBSBOT hardware module. |
| Search utilities | `modules.programs.cli.search.enable` | Installs `ack`, `ripgrep`, and `fd` as a focused text and filesystem search toolset. |
| System utilities | `modules.programs.cli.system.enable` | Installs `coreutils` and `pciutils` as foundational command-line inspection tools. |
| Waybar | `modules.programs.waybar.enable` | Enables Waybar as a standalone program feature for desktop environments that use it. |

## AI coding clients

| Module | Option | Responsibility |
|---|---|---|
| AI client selector | `modules.ai.enable`, `.client` | Installs the selected AI coding client through one host-level interface. The initial `"kimi"` choice maps to `pkgs.kimi-code`; the enum and package map are the extension points for future clients such as Claude Code. |
| Kimi credentials | `modules.ai.kimi.encryptedConfig`, `.identityPaths` | Uses age and the first matching user SSH identity to decrypt the host-specific private-input payload at login, then atomically installs `~/.kimi-code/config.toml` with mode `0600` without placing plaintext in the Nix store. |

## Development, shell, and version-control features

| Module | Option | Responsibility |
|---|---|---|
| C and C++ | `modules.develop.cc.enable` | Provides GCC, Clang, CMake, Make, GDB, pkg-config, and Clang tooling. |
| Rust | `modules.develop.rust.enable`, `.channel`, `.version`, `.targets`, `.toolchain` | Resolves one configurable rust-overlay stable or nightly toolchain for the host, including Cargo, rustc, rustfmt, Clippy, rust-analyzer, `rust-src`, and any declaratively selected compilation targets; `smunix` selects stable 1.98.1, and the read-only resolved channel, version, and toolchain are shared with dependent modules. The nullable `.nightlyVersion` option remains only as a deprecated compatibility alias. |
| Dioxus | `modules.develop.dioxus.enable`, `.desktop.enable`, `.desktop.libclangPackage`, `.web.*`, `.android.*` | Requires the shared Rust module; installs the reproducibly pinned Dioxus 0.8.0-alpha.1 `dx` CLI, Linux GTK3/WebKitGTK/DBus desktop dependencies with deterministic closure-derived GLib, GIO, GObject, Pango, ATK, Cairo, GDK Pixbuf, pkg-config, data, GIO-module, and runtime paths, plus a configurable libclang package, comprehensive runtime and development `LIBRARY_PATH`, and focused Dioxus patch that injects every native search directory into both hot-patching fat-link commands; declarative `wasm32-unknown-unknown` web support with configurable exact `wasm-bindgen-cli` selection and Binaryen `wasm-opt`, or Android Studio plus a declarative API-35 SDK, Build Tools 35.0.0, NDK 27.2.12479018, CMake 3.22.1, emulator, Google APIs x86_64 image, Java 17, environment variables, KVM access, and the four requested Rust Android targets. |
| Aya/eBPF | `modules.develop.aya.enable`, `.vm.enable` | Requires the Rust module and reuses its configured stable 1.98.1 toolchain and cargo-generate through `aya-cargo` and `aya-rustc`; the wrappers scope `RUSTC_BOOTSTRAP=1` only to Aya’s tier-three BPF `build-std` operation; also provides pinned `aya-tool`, exact `bpf-linker` 0.11.1, bpftool, bpftrace, pahole, LLVM, tcpdump, and KVM access. The same stable Rust 1.98.1 compiler, `bpf-linker`, `aya-tool`, and bpftrace packages are installed inside the VM, where `RUSTC_BOOTSTRAP=1` is scoped to the Aya laboratory for tier-three BPF `build-std` support. The optional `ebpf-vm` command launches an isolated BPF/BTF/BPF-LSM NixOS laboratory, mounts its required `--shared-directory` path at `/host`, and forwards host loopback port 2222 to dev-only guest SSH, automatically authorizes a selected host public key, retains `dev` password recovery, and denies root SSH. |
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
| Printing | `modules.hardware.printing.enable`, `.drivers`, `.networkDiscovery.*` | Enables CUPS and optional legacy drivers. Network discovery uses Avahi mDNS/DNS-SD, optional IPv4 `.local` resolution, UDP 5353 firewall access, and optional `cups-browsed` automatic queue creation without advertising this host’s queues or exposing its CUPS server to the LAN. |
| Power selector | `modules.hardware.power.backend` | Selects `upower` or `tlp`; TLP remains the policy engine while retaining UPower for desktop battery telemetry. |
| TLP | `modules.hardware.power.tlp.enable` | Disables the conflicting power-profiles daemon, enables TLP and its profile compatibility service, configures AC/battery CPU policies, runtime PCI power management, and configurable BAT0 charge thresholds. |
| UPower | `modules.hardware.power.upower.enable` | Provides percentage-based battery telemetry, warning levels, desktop integration, and critical-power handling. |
| Lid actions | `modules.hardware.power.lid.enable` | Configures logind actions for lid closure on battery, external power, and while docked. |
| NVIDIA PRIME | `modules.hardware.nvidia.enable`, `.powerManagement.*`, `.prime.*` | Enables NVIDIA graphics, modesetting, the open kernel module, settings tools, and required host-specific PCI bus IDs. Power preservation, fine-grained runtime PM, PRIME sync, PRIME offload, and the `nvidia-offload` helper are independently selectable with assertions that reject incompatible combinations. |
| Passwordless sudo | `modules.security.passwordlessSudo.enable` | Grants the configured primary user a `NOPASSWD` sudo rule without changing the password requirement for other wheel users; retained as an opt-in feature but disabled on `smunix`. |
| Fingerprint authentication | `modules.security.fingerprint.enable` | Enables fprintd and scoped fingerprint PAM authentication for interactive login, unlock, and privilege prompts while excluding password/account mutation and noninteractive services. A typed list selects multiple fingers for generated enrollment, listing, and sequential verification helpers; YubiKey and password fallback remain available. |
| YubiKey U2F | `modules.security.yubikey.enable` | Enables passwordless PAM authentication with password fallback, deploys a central private-input mapping, installs hardware support, and optionally locks sessions when a Yubico USB device is removed. |
| LUKS FIDO2 | `modules.security.luksFido2.enable` | Enables the systemd initrd and its FIDO2 support, then adds enrolled-token discovery to selected host-declared LUKS2 devices while preserving passphrase fallback. |

## Flake composition and extension points

| Component | Location | Responsibility |
|---|---|---|
| flake-parts entry point | `flake.nix` | Declares inputs and delegates output composition to flake-parts. |
| Top-level flake outputs | `parts/flake.nix` | Exports the helper library, overlays, recursive NixOS and Home Manager module trees, and discovered NixOS hosts. |
| Per-system outputs | `parts/per-system.nix` | Defines packages and the Alejandra formatter for supported systems. |
| Private source input | `inputs.secrets` | Supplies host-specific U2F mappings and age-encrypted application payloads as a pinned non-flake input. The Kimi ciphertext resides at `hosts/smunix/apps/kimi-code/config.toml.age`. |
| Kimi Code input | `inputs.kimi-code` | Supplies the upstream system-specific Kimi Code package while retaining its own pinned build toolchain. |
| Discovery helpers | `lib/attrs.nix`, `lib/modules.nix`, `lib/nixos.nix` | Provide attribute helpers, filesystem-based module discovery, and automatic host construction. |
| Custom package overlay | `overlays/additions.nix` | Extension point for locally packaged additions. |
| Package modification overlay | `overlays/modifications.nix` | Extension point for package overrides. |
| Unstable package overlay | `overlays/unstable-packages.nix` | Exposes the pinned unstable package set under the configured overlay. |
| Kimi Code overlay | `overlays/kimi-code.nix` | Exposes the upstream package as `pkgs.kimi-code` to the host module graph. |
| OBS and NDI compatibility overlay | `overlays/obs-plugins.nix` | Replaces only the stale `ndi-6` source hash, rebuilds DistroAV against that corrected SDK derivation, and exposes it as `pkgs.obs-studio-plugins.obs-ndi`. |
| Custom package set | `pkgs/default.nix`, `pkgs/rust-toolchain-policy.nix` | Builds the Rust-based `aya-tool`, Dioxus CLI 0.8.0-alpha.1, and wasm-bindgen CLI 0.2.128 packages with the same stable Rust 1.98.1 policy selected by `smunix`, and exports them with the exact prebuilt `bpf-linker` through the additions overlay. Per-system outputs additionally expose the Aya/eBPF NixOS VM and `ebpf-vm` launcher on x86_64 Linux. |

## Feature selection

The `smunix` manifest enables Plasma and the Niri/Noctalia desktop, NetworkManager, PipeWire, CUPS printing with Avahi/DNS-SD network discovery and automatic driverless queues, TLP with UPower telemetry, suspend-on-lid-close behavior, NVIDIA PRIME sync with disabled NVIDIA power management and host-specific PCI IDs, an ASUS DP-5 portrait-left/eDP-1 HiDPI-right layout generated for the pinned unstable Niri package with all named workspaces assigned to DP-5 and `Mod+O` focused-window monitor movement, automatic Tail 2 UVC detection and DJI Mic 3 PipeWire routing, the search and system utility groups, the language toolchains including Typst and centrally configured stable Rust 1.98.1 shared with Aya/eBPF and Dioxus, Dioxus desktop and web support plus Android Studio/SDK/NDK/emulator integration with `wasm32-unknown-unknown`, exact wasm-bindgen CLI 0.2.128, and four Android Rust targets, Aya’s exact bpf-linker, and isolated `ebpf-vm` laboratory, Kimi Code through the AI client selector, Nushell, Starship, Zellij, Ghostty as the default terminal, WezTerm as an alternative, Brave, Firefox, OBS Studio with NDI and a V4L2 virtual camera, Discord, Signal, Git, Jujutsu, Helix, Vim, Zed, the compact-font policy at a 20 percent reduction, automatic Plasma and Noctalia screen locking, Niri-only Gammastep at 6500 K by day and 3500 K after sunset using GeoClue automatic location with a bounded J0N 1P0 fallback, multi-finger enrollment and fingerprint authentication, YubiKey U2F authentication with password fallback, systemd-initrd FIDO2 unlocking for encrypted root and swap, and the shared Home Manager base/package profiles. Niri additionally supplies XTerm, Okular, Evince, and Dolphin for its routed workspaces. The separate TDF, Zathura, and MPV viewer modules are enabled for terminal and graphical document or media viewing. An Xpdf routing rule is present, but the pinned insecure Xpdf package is intentionally not installed. The standalone Waybar module remains reusable but is not selected because Noctalia owns Niri’s bar.
