<div align="center"><img src=".assets/logo_nixos.png" width="320" alt="NixOS Configuration Logo"></div>
<h1 align="center">Klein Moretti's NixOS Configuration</h1>

<div align="center">

![nixos](https://img.shields.io/badge/NixOS-24273A.svg?style=flat&logo=nixos&logoColor=CAD3F5)
![nixpkgs](https://img.shields.io/badge/nixpkgs-26.05-informational.svg?style=flat&logo=nixos&logoColor=CAD3F5&colorA=24273A&colorB=8aadf4)
![linux kernel](https://img.shields.io/badge/kernel-zen-informational.svg?style=flat&logo=linux&logoColor=f4dbd6&colorA=24273A&colorB=b7bdf8)
![niri](https://img.shields.io/badge/niri-rolling-informational.svg?style=flat&logo=wayland&logoColor=eed49f&colorA=24273A&colorB=91d7e3)
![hyprland](https://img.shields.io/badge/hyprland-informational.svg?style=flat&logo=wayland&logoColor=eed49f&colorA=24273A&colorB=91d7e3)
![rust](https://img.shields.io/badge/rust-stable-informational.svg?style=flat&logo=rust&logoColor=f5a97f&colorA=24273A&colorB=f5a97f)

</div>

Modular, declarative NixOS flake featuring Home Manager integration, an ephemeral root with Btrfs impermanence, secure secrets management via sops-nix, a customized local AI stack, performance optimization, an ergonomic Distrobox container engine, and custom CLI terminal scripts.

---

## 🏗️ Architecture

```text
.
├── flake.nix                    # Entry point — inputs, outputs, system configuration wiring
└── modules/
    ├── _lib/                    # Custom Nix library, builder engine (mkModule, distrobox helpers), and package exports
    ├── ai/                      # AI stack: Ollama, llama.cpp (Ivy Bridge optimized), Open WebUI, MCP configs, tools
    ├── apps/                    # Home Manager applications & user settings (browsers, editors, terminal, gaming, media)
    ├── core/                    # System core: bootloader (GRUB2+grubfm), fonts, graphics, kernel (Zen), memory, nix settings
    ├── desktop/                 # Desktop Managers & Themes: KDE, GNOME, Niri, Hyprland, Themeing (Colloid/Vimix)
    ├── hardware/                # Hardware-level: mounting, preservation (impermanence)
    ├── hosts/                   # Host-specific configurations (KleinMoretti, hardware spec, single source of truth)
    ├── security/                # Security & Secrets: sops, hardening, gnupg, auth (sudo-rs)
    ├── services/                # System services: networking (zapret, cloudflare-warp, dns, vpn), snapper, ssd-monitor, restic
    ├── settings/                # HM settings: identity, file symlinks
    ├── specialization/          # Performance & Retro gaming modes
    └── virtualisation/          # Podman, Distrobox engine & unified dbox CLI, Waydroid, libvirt
```

---

## 🛠️ Key Features & Technical Details

### 1. System Core & Architecture
* **Single Source of Truth (`modules/hosts/nixos/users/default.nix`)** — System features and application suites are toggled per-user under `userFeatures`. The builder dynamically maps these flat flags to system options via `selfLib.mapFeatures` and `lib.recursiveUpdate`.
* **Unified Module Builder (`selfLib.mkModule`)** — Consolidates system options, Home Manager configs (`hmConfig`), Flatpak options (`flatpakCfg`), and Distrobox container configurations (`distroboxCfg`) in a single boilerplate-free module definition.
* **Bootloader (`modules/core/bootloader.nix`)** — Utilizes GRUB2 (disabling systemd-boot) with full EFI support, styled with the `catppuccin-grub` theme. Features an activation script (`setupGrubFM`) that installs and chainloads the **Grub2 File Manager** (`grubfmx64.efi`) directly from the EFI partition.
* **Kernel & Tuning (`modules/core/kernel/`)** — Boots the interactive-optimized **Zen Kernel** (`linuxPackages_zen`). Applies workarounds for Gen 3 Intel Ivy Bridge graphics (disabling i915 FBC/PSR) to prevent rendering glitches. Tunes TCP congestion control with CAKE (`sch_cake`) and BBR (`tcp_bbr`), disables IPv6, and optimizes sysctl limits.
* **Memory Tuning (`modules/core/memory.nix`)** — Configures Zram swap with 100% RAM allocation using `zstd` compression. Mounts `/tmp` on a RAM-backed tmpfs (capped at 60%), and tunes VM swappiness (`vm.swappiness = 180`) and cache pressure (`vm.vfs_cache_pressure = 50`) to optimize memory longevity.
* **Nix Settings & Hardening (`modules/core/nix.nix`)** — Sets up multi-source binary caches (caches for NixOS, nix-community, Cachix, Niri, Hyprland). Routes nix-daemon network calls through a local SOCKS5 proxy to bypass local blocks, and injects private GitHub tokens using SOPS secrets to raise download API rate limits.

### 2. Transient Root & Btrfs Preservation
* **Ephemeral Wiping (`modules/hardware/preservation.nix`)** — Mounts and wipes the Btrfs subvolumes `@nixos-root` and `@nixos-home` during the initrd stage. Prior to deletion, the system backs up old roots/homes into timestamps and stores user home snapshots in `@nixos-persist/home-snapshots/`.
* **Post-Boot Cleanup** — Wiping operations are deferred to a background systemd service (`preservation-cleanup.service`) to keep boot times fast, automatically retaining only the last 20 roots, homes, and snapshots.
* **Declarative Preservation** — Sourced via the `preservation` module under `/persist`. Persists system directories (NetworkManager, Bluetooth keys, Docker/Waydroid, Ollama, wireproxy) and user directories (Documents, configs, SSH, GPG, browser profiles, Steam). System logs are preserved cleanly on a dedicated Btrfs subvolume (`subvol=@nixos-log`).

### 3. Declarative Distrobox & Hybrid Container Stack
* **Co-located Container Declarations (`distroboxCfg`)** — Application modules (Firefox, Bitwarden, yt-dlp, gallery-dl, aria2) declare container dependencies directly in their module via `selfLib.distrobox.<distro>`. The engine merges shared containers automatically into `my._distroboxRegistry`.
* **Modular Feature Plugin System (`modules/_lib/modules/distrobox-helper/features/`)**:
  * **Chaotic-AUR (`chaoticAur = true`)** — Injects Chaotic-AUR repository, keyring, and mirrorlist for Arch Linux containers, allowing instant installation of pre-compiled binary packages via `pacman`.
  * **Arch Testing (`extraTesting = true`)** — Enables `[extra-testing]` for bleeding-edge upstream releases (e.g. latest Bitwarden).
  * **Fedora COPR & RPM Fusion** — Supports `copr = [ "repo" ]` and `rpmfusion.free = true` / `rpmfusion.unfree = true`.
  * **Declarative Guest Symlinks** — Maps host-to-guest file structures (`symlinks = { "/container/path" = "/host/path"; }`).
  * **Debdelta Updates** — Automated delta update support for Debian and Ubuntu containers.
  * **AUR Build Automation (`aur = [ ... ]`)** — Automatically handles `makepkg` compilation for unbundled AUR packages.
* **Self-Healing Host Wrappers (`packages.nix`)** — Generates host binary wrappers in `home.packages` that enter containers transparently, auto-initializing containers from declarative config if missing. Supports Home Manager program injection (`passWrapperAsPackage = true`).
* **Automated Container Lifecycle (`podman.nix`)** — Background systemd timers for automatic container updates (`distrobox-autoupdate`), orphan container pruning (`distrobox-prune`), and X11/XWayland GUI display authorization (`~/.distroboxrc` with `xhost`).

### 4. Privilege Escalation & Security
* **Memory-Safe Escalation (`modules/security/auth/`)** — Replaces standard `sudo` and `doas` with the memory-safe Rust implementation **`sudo-rs`** (`security.sudo-rs.enable = true`), restricting execution strictly to the wheel group (`execWheelOnly = true`).
* **Secrets Management (`modules/security/secrets.nix`)** — Decrypts API tokens, SSH keys, binary files, and VPN profiles via `sops-nix` using the system's SSH host key. Dynamically generates configurations (`gh` hosts, Kaggle tokens, Cachix credentials) and injects hashed user passwords into user accounts declaratively (`mutableUsers = false`).

### 5. Desktop Environments & Themes
* **Themeing (`modules/desktop/theme.nix`)** — Unified GTK themeing featuring `Colloid-Dark` (compact), `Vimix-white-cursors`, `Tela-circle-dark` icons, and `JetBrainsMono Nerd Font` for a premium, consistent visual style.
* **GNOME & KDE Plasma (`modules/desktop/`)** — Lightweight, debloated installations. GNOME excludes 20+ core packages and adds curated extensions (Vitals, Blur-my-Shell). KDE disables Elisa, Baloo indexing, Elisa, and Okular, tuning crash handlers to fail silently (`KCRASH_CORE_PATTERN_RAISE = 1`).
* **Hyprland (`modules/desktop/hyprland/`)** — Sourced with Matugen generated palettes, integrated with **UWSM** (`withUWSM = true`). Binds hotkeys to custom Quickshell Nandoroid IPC triggers (spotlight, notification drawer, dashboard, region tools).
* **Niri (`modules/desktop/niri/`)** — Configures a scrollable tiling workspace with customized window borders (active gray, urgent red). Sets rules for tiled vs. floating states, and imports DankMaterialShell styles.

### 6. Application Suites & Browser Profiles
* **Firefox (`modules/apps/browsers/firefox/`)** — Configures a **Default Profile** (preloaded with Bitwarden, uBlock, Simple Tab Groups, containers) and a **Hardened Profile** (aggressive fingerprinting, disabled WebGL/WebRTC/Geolocation). Restricts 50+ telemetry/Pocket parameters declaratively. Resolves Gecko's random directory issue by copying and patching `profiles.ini` dynamically.
* **Zen Browser (`modules/apps/browsers/zen/`)** — Implements a VA-API hardware decoding workaround (mounting `/run/opengl-driver/lib/dri:ro`, preloading `libva` libraries, disabling RDD sandbox) to match the Ivy Bridge GPU. Resolves Flatpak symlink boundary violations by linking only the profile directory.
* **Profile Sync Daemon (`modules/apps/browsers/psd.nix`)** — Syncs browser profiles into a RAM disk to accelerate I/O and minimize SSD wear. Migrated to **OverlayFS mode** (`USE_OVERLAYFS = "yes"`), caching only delta changes to save memory. Grants passwordless `sudo-rs` privileges for `psd-overlay-helper` (patched to use coreutils `runuser -u` to bypass TTY requirements).
* **VSCodium (`modules/apps/editors/vscodium/`)** — Configured declaratively (`mutableExtensionsDir = false`). Compiles marketplace extensions (RunOnSave, sqlfluff, sqlite-viewer) out-of-store via `buildVscodeMarketplaceExtension` and configures default language formatters (`nixfmt`, `black`, `shfmt`).
* **Shell & Terminals** — Fish shell utilizes a custom blacklist (`fish_should_add_to_history`) preventing sensitive tokens or blacklisted commands from writing to disk. Includes shortcuts (`,` and `,,`) for running Nix shells. Zellij, Foot, and Tmux are pre-styled with Catppuccin themes.

### 7. AI Stack & MCP Infrastructure
* **Ivy Bridge Llama.cpp (`modules/ai/runtimes/llama.nix`)** — Overrides the `llama-cpp` package to compile a localized build, disabling AVX2 and FMA (unsupported by Ivy Bridge CPUs) while target-optimizing with `-march=ivybridge`.
* **Declarative MCP Setup (`modules/ai/tools/mcp/`)** — Provisions native Model Context Protocol servers (`nixos`, `search` (free-search-mcp), `scrapling`, `ai-memory`, `cloudflare`, etc.) for Gemini/Antigravity CLI and OpenCode. Wraps stdio servers inside graceful exit traps (`mcpWrapper`) to handle session terminations cleanly.
* **LLM Engine & Web UI** — Integrates Ollama and Open WebUI services, binding their systemd lifecycles (`bindsTo` / `wants`) so starting Ollama automatically launches the Web UI. Disables rebuild-induced service restarts (`restartIfChanged = false`).

### 8. Services & Cloud Backups
* **DPI Bypass (`modules/services/networking/zapret.nix`)** — Deploys the Zapret engine with split-packet mode (`--dpi-desync=split2`). Avoids iptables/nftables conflicts by disabling auto-firewall rules.
* **Cloudflare WARP proxy (`modules/services/networking/cloudflare-warp.nix`)** — Runs `wireproxy` SOCKS5 proxy on port `40000` with automated profile generation (`wgcf register`), state persistence via `StateDirectory`, and TCP keep-alive injection.
* **Secure DNS (`modules/services/networking/dns.nix`)** — Bypasses systemd-resolved, mapping DNS queries to `dnscrypt-proxy` resolving via NextDNS. Generates authenticated configurations dynamically from secrets.
* **Hourly Snapper Snapshots (`modules/services/scheduling/snapper.nix`)** — Automates Btrfs snapshots of the `/persist` directory. Timeline cleanups are scheduled at hourly marks (`OnCalendar = "*-*-* *:30:00"`) to avoid space issues.
* **SSD TBW/TBR Tracker (`modules/services/scheduling/ssd-monitor.nix`)** — Triggers an hourly script tracking SSD read/write bytes since boot (incorporating a custom LBA multiplier for MidasForce SATA drives). Spawns a Python helper (`cgroup-monitor.py`) crawling cgroup namespaces to identify top I/O consumers.
* **Restic Backups (`modules/services/storage/restic.nix`)** — Daily encrypted backups sent to a cloud repository using an isolated rclone wrapper proxy that forces traffic through WARP. Features on-demand backups mounting (`restic-mount`) via FUSE.
* **Btrfs NoCOW Automation (`modules/services/storage/btrfs-nocow-migration.nix`)** — Automatically disables copy-on-write (`+C`) on system databases (Docker, Waydroid, Nix DBs) and user caches (browser cache, Materialgram tdata) to avoid write amplification.

---

## 🛠️ CLI Utilities & Custom Scripts

This configuration provides a custom suite of terminal tools to manage connections, containers, updates, and system debugging:

*   **`dbox` / `dbox-pkg`** — Unified Distrobox CLI manager:
    *   `dbox status` / `dbox list` — View active containers, execution states, detected package managers, and base images.
    *   `dbox enter [c]` / `dbox run <c> <cmd...>` — Enter or execute commands inside containers directly.
    *   `dbox build` / `dbox assemble` — Rebuild and assemble containers from `containers.ini`.
    *   `dbox sync` — Synchronize packages and hooks declared in NixOS configuration.
    *   `dbox prune` — Clean unmanaged / orphan containers.
    *   `dbox install` / `remove` / `search` / `update` / `upgrade` — Universal package management across container distros.
    *   Direct shortcuts: `dbox-pacman`, `dbox-apt`, `dbox-dnf`, `dbox-apk`, `dbox-zypper`, `dbox-xbps`.
*   **`vpn-on` / `vpn-switch` / `vpn-off`** — Decrypts ProtonVPN configs, strips default DNS blocks, injects custom NextDNS resolvers, and boots `wireproxy` on port 1080.
*   **`nfui` (Nix Flake Update Interactive)** — Interactive CLI wrapping `nix flake update`. Provides an `fzf` multi-select menu allowing users to pin-point which inputs to update, automatically reverting unselected input hashes using `jq` edits against a lock backup.
*   **`ollama-to-llama`** — Translates local Ollama models and their Modelfile parameters (system prompts, context, temperature, penalties) into matching `llama-cli` flags, launching them directly using the local GGUF model binaries.
*   **`show-zombie-parents`** — Queries and prints PPIDs and process details of parent processes currently holding defunct/zombie child states.
*   **`dl-lagu`** — Downloads high-quality MP3 audio files from YouTube, automatically embedding metadata, search fallbacks, and thumbnails.

---

## 🧩 Developer Guide

### Module Convention (`selfLib.mkModule`)

Every feature module uses `selfLib.mkModule` — a unified builder that auto-creates
`options.my.<name>.enable` and wires NixOS + Home Manager config under a single toggle:

```nix
{ pkgs, selfLib, ... }:

selfLib.mkModule {
  name        = "apps.office.example";   # dot-path → options.my.apps.office.example.enable
  description = "Short description";

  nixosConfig  = { ... };                 # system-level config (active when enable = true)
  hmConfig     = hmOpts: { ... };         # home-manager config (receives hmOpts.config, hmOpts.osConfig)
  flatpakCfg   = { "com.app.Id" = { enable = true; origin = "flathub"; binName = "app"; }; };
  distroboxCfg = selfLib.distrobox.arch {
    packages = with pkgs; [ aria2 ];
    package  = pkgs.aria2;               # native fallback if distrobox mode is disabled
  };
  preservation = { persist = true; directories = [ "/var/lib/example" ]; };
}
```

### Distrobox Helper (`selfLib.distrobox.<distro>`)

The builder helper supports polymorphic forms:
1. **Shared Container (Default Name)**:
   ```nix
   distroboxCfg = selfLib.distrobox.arch {
     chaoticAur   = true;                     # Enable Chaotic-AUR pre-built binaries
     extraTesting = true;                     # Enable [extra-testing] repo
     packages     = [ "bitwarden" "ffmpeg" ];
     package      = pkgs.bitwarden-desktop;   # Native fallback package
   };
   ```
2. **Dedicated / Named Container**:
   ```nix
   distroboxCfg = selfLib.distrobox.fedora "dev-fedora" {
     copr     = [ "atim/starship" ];
     packages = [ "starship" ];
   };
   ```

### Feature Toggles (`userFeatures`)

All features are toggled via [`modules/hosts/KleinMoretti/users/default.nix`](file:///home/klein-moretti/nixos-config/modules/hosts/KleinMoretti/users/default.nix).
Set a key to `true`/`false` — the `mapFeatures` transformer converts it to `{ enable = true/false; }`.

### Adding a New Host

1. Create `modules/hosts/<HostName>/` with subdirs: `default.nix`, `home/`, `hardware-configuration/`, `users/`
2. Copy `users/default.nix` from `KleinMoretti` and adjust settings
3. In `flake.nix`, add to `mkNixosConfigurations`:
   ```nix
   mkNixosConfigurations = {
     KleinMoretti = builders.mkNixosConfiguration "KleinMoretti";
     NewHost      = builders.mkNixosConfiguration "NewHost";     # ← add
   };
   ```

### Adding a New Module

1. Create `modules/<domain>/<name>.nix` using `selfLib.mkModule`
2. Register the feature path in `modules/hosts/<HostName>/users/default.nix`
3. The `scanPaths` traverser auto-discovers it — no manual import needed

### Web App (PWA) Helper

Use `selfLib.mkWebApp pkgs { ... }` to create a Chromium/Brave app-mode launcher with `.desktop` entry:

```nix
home.packages = [
  (selfLib.mkWebApp pkgs {
    name        = "my-app";
    desktopName = "My App";
    url         = "https://app.example.com";
    browser     = "brave";        # "chromium" | "brave" | "firefox" (via flatpak) | "librewolf"
    wmClass     = "app.example.com";
    osConfig    = hmOpts.osConfig;
  })
];
```

### Secrets Management

Secrets are encrypted with `sops-nix`. To add a new secret:
```bash
# Edit secrets file
sops modules/security/secrets.yaml
# Reference in Nix
sops.secrets."my-secret" = { sopsFile = ./secrets.yaml; owner = "root"; };
```

---

## 💻 Quick Start & Verification

```bash
# Enter devShell (nixfmt, statix, deadnix, nom, nvd tools)
nix develop

# Verify syntax and evaluation rules
nix flake check
```

---

## ⚖️ License

MIT
