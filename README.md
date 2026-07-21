# ❄️ Klein Moretti's NixOS Configuration

![NixOS](https://img.shields.io/badge/NixOS-30343f?style=flat&logo=nixos&logoColor=7eb3e6)
![nixpkgs](https://img.shields.io/badge/nixpkgs-unstable-7eb3e6?style=flat&logo=nixos&logoColor=7eb3e6&labelColor=30343f)
![kernel](https://img.shields.io/badge/kernel-zen-a2a7f5?style=flat&logo=linux&logoColor=a2a7f5&labelColor=30343f)
![desktop](https://img.shields.io/badge/desktop-niri/hyprland-86d1fc?style=flat&logo=wayland&logoColor=86d1fc&labelColor=30343f)
![browser](https://img.shields.io/badge/browser-zen/firefox-fca3a7?style=flat&logo=firefox-browser&logoColor=fca3a7&labelColor=30343f)
![shell](https://img.shields.io/badge/shell-fish-f7ca94?style=flat&logo=fishshell&logoColor=f7ca94&labelColor=30343f)

Modular, declarative NixOS flake featuring Home Manager integration, an ephemeral root with Btrfs impermanence, secure secrets management via sops-nix, a customized local AI stack, performance optimization, and custom CLI terminal scripts.

---

## 🏗️ Architecture

```text
.
├── flake.nix                    # Entry point — inputs, outputs, system configuration wiring
├── dotfiles/                    # Repository-managed dotfiles (Niri, Quickshell Nandoroid, Matugen, DankMaterialShell)
├── lib/
│   ├── default.nix              # Public API for custom library functions (scanPaths, mapFeatures)
│   ├── builders.nix             # NixOS + Home Manager unified configuration builders
│   ├── browser-addons.nix       # Shared Firefox/Zen addon builders and policy overrides
│   └── modules/                 # Module helper engine (mkModule & flatpak-helper)
│
├── hosts/
│   └── nixos/
│       ├── default.nix          # Host-specific overrides, user configuration, and feature linking
│       ├── home.nix             # Home Manager wiring
│       ├── users.nix            # User definitions and feature flags (Single Source of Truth)
│       └── hardware-configuration.nix
│
├── modules/
│   ├── ai/                      # AI stack: Ollama, llama.cpp (Ivy Bridge optimized), Open WebUI, MCP configs, tools
│   ├── apps/                    # Home Manager applications & user settings (browsers, editors, terminal, gaming, media)
│   ├── core/                    # System core: bootloader (GRUB2+grubfm), fonts, graphics, kernel (Zen), memory, nix settings
│   ├── desktop/                 # Desktop Managers & Themes: KDE, GNOME, Niri, Hyprland, Themeing (Colloid/Vimix)
│   ├── hardware/                # Hardware-level: mounting, preservation (impermanence)
│   ├── scripts/                 # Custom CLI tools and utility scripts
│   ├── security/                # Security & Secrets: sops, hardening, gnupg, auth (sudo-rs)
│   ├── services/                # System services: networking (zapret, cloudflare-warp, dns, vpn), snapper, ssd-monitor, restic
│   ├── settings/                # HM settings: identity, file symlinks
│   ├── specialization/          # Performance & Retro gaming modes
│   └── virtualisation/          # Docker, Waydroid, libvirt
│
├── secrets/                     # Encrypted via sops-nix (age)
│   ├── secrets.yaml             # Main secrets file (API keys, passwords, credentials)
│   ├── binary/                  # Encrypted binary secrets (wg-configs, credentials)
│   └── vpn-files/               # Decrypted-on-the-fly WireGuard profile configurations
│
└── packages-export.nix          # Unified export for custom derivations (caching target)
```

---

## 🛠️ Key Features & Technical Details

### 1. System Core & Architecture
* **Single Source of Truth (`hosts/nixos/users.nix`)** — System features and application suites are toggled per-user under `userFeatures`. The builder dynamically maps these flat flags to system options via `selfLib.mapFeatures` and `lib.recursiveUpdate`.
* **Unified Module Builder (`selfLib.mkModule`)** — Consolidates system options, Home Manager configs (`hmConfig`), and Flatpak options (`flatpakCfg`) in a single boilerplate-free module definition.
* **Bootloader (`modules/core/bootloader.nix`)** — Utilizes GRUB2 (disabling systemd-boot) with full EFI support, styled with the `catppuccin-grub` theme. Features an activation script (`setupGrubFM`) that installs and chainloads the **Grub2 File Manager** (`grubfmx64.efi`) directly from the EFI partition.
* **Kernel & Tuning (`modules/core/kernel.nix`)** — Boots the interactive-optimized **Zen Kernel** (`linuxPackages_zen`). Applies workarounds for Gen 3 Intel Ivy Bridge graphics (disabling i915 FBC/PSR) to prevent rendering glitches. Tunes TCP congestion control with CAKE (`sch_cake`) and BBR (`tcp_bbr`), disables IPv6, and optimizes sysctl limits.
* **Memory Tuning (`modules/core/memory.nix`)** — Configures Zram swap with 100% RAM allocation using `zstd` compression. Mounts `/tmp` on a RAM-backed tmpfs (capped at 60%), and tunes VM swappiness (`vm.swappiness = 180`) and cache pressure (`vm.vfs_cache_pressure = 50`) to optimize memory longevity.
* **Nix Settings & Hardening (`modules/core/nix.nix`)** — Sets up multi-source binary caches (caches for NixOS, nix-community, Cachix, Niri, Hyprland). Routes nix-daemon network calls through a local SOCKS5 proxy to bypass local blocks, and injects private GitHub tokens using SOPS secrets to raise download API rate limits.

### 2. Transient Root & Btrfs Preservation
* **Ephemeral Wiping (`modules/hardware/preservation.nix`)** — Mounts and wipes the Btrfs subvolumes `@nixos-root` and `@nixos-home` during the initrd stage. Prior to deletion, the system backs up old roots/homes into timestamps and stores user home snapshots in `@nixos-persist/home-snapshots/`.
* **Post-Boot Cleanup** — Wiping operations are deferred to a background systemd service (`preservation-cleanup.service`) to keep boot times fast, automatically retaining only the last 20 roots, homes, and snapshots.
* **Declarative Preservation** — Sourced via the `preservation` module under `/persist`. Persists system directories (NetworkManager, Bluetooth keys, Docker/Waydroid, Ollama, wireproxy) and user directories (Documents, configs, SSH, GPG, browser profiles, Steam). System logs are preserved cleanly on a dedicated Btrfs subvolume (`subvol=@nixos-log`).

### 3. Privilege Escalation & Security
* **Memory-Safe Escalation (`modules/security/auth.nix`)** — Replaces standard `sudo` and `doas` with the memory-safe Rust implementation **`sudo-rs`** (`security.sudo-rs.enable = true`), restricting execution strictly to the wheel group (`execWheelOnly = true`).
* **Secrets Management (`modules/security/secrets.nix`)** — Decrypts API tokens, SSH keys, binary files, and VPN profiles via `sops-nix` using the system's SSH host key. Dynamically generates configurations (`gh` hosts, Kaggle tokens, Cachix credentials) and injects hashed user passwords into user accounts declaratively (`mutableUsers = false`).

### 4. Desktop Environments & Themes
* **Themeing (`modules/desktop/theme.nix`)** — Unified GTK themeing featuring `Colloid-Dark` (compact), `Vimix-white-cursors`, `Tela-circle-dark` icons, and `JetBrainsMono Nerd Font` for a premium, consistent visual style.
* **GNOME & KDE Plasma (`modules/desktop/`)** — Lightweight, debloated installations. GNOME excludes 20+ core packages and adds curated extensions (Vitals, Blur-my-Shell). KDE disables Elisa, Baloo indexing, Elisa, and Okular, tuning crash handlers to fail silently (`KCRASH_CORE_PATTERN_RAISE = 1`).
* **Hyprland (`modules/desktop/hyprland/`)** — Sourced with Matugen generated palettes, integrated with **UWSM** (`withUWSM = true`). Binds hotkeys to custom Quickshell Nandoroid IPC triggers (spotlight, notification drawer, dashboard, region tools).
* **Niri (`modules/desktop/niri/`)** — Configures a scrollable tiling workspace with customized window borders (active gray, urgent red). Sets rules for tiled vs. floating states, and imports DankMaterialShell styles.

### 5. Application Suites & Browser Profiles
* **Firefox (`modules/apps/browsers/firefox/`)** — Configures a **Default Profile** (preloaded with Bitwarden, uBlock, Simple Tab Groups, containers) and a **Hardened Profile** (aggressive fingerprinting, disabled WebGL/WebRTC/Geolocation). Restricts 50+ telemetry/Pocket parameters declaratively. Resolves Gecko's random directory issue by copying and patching `profiles.ini` dynamically.
* **Zen Browser (`modules/apps/browsers/zen/`)** — Implements a VA-API hardware decoding workaround (mounting `/run/opengl-driver/lib/dri:ro`, preloading `libva` libraries, disabling RDD sandbox) to match the Ivy Bridge GPU. Resolves Flatpak symlink boundary violations by linking only the profile directory.
* **Profile Sync Daemon (`modules/apps/browsers/psd.nix`)** — Syncs browser profiles into a RAM disk to accelerate I/O and minimize SSD wear. Migrated to **OverlayFS mode** (`USE_OVERLAYFS = "yes"`), caching only delta changes to save memory. Grants passwordless `sudo-rs` privileges for `psd-overlay-helper` (patched to use coreutils `runuser -u` to bypass TTY requirements).
* **VSCodium (`modules/apps/editors/vscodium.nix`)** — Configured declaratively (`mutableExtensionsDir = false`). Compiles marketplace extensions (RunOnSave, sqlfluff, sqlite-viewer) out-of-store via `buildVscodeMarketplaceExtension` and configures default language formatters (`nixfmt`, `black`, `shfmt`).
* **Shell & Terminals** — Fish shell utilizes a custom blacklist (`fish_should_add_to_history`) preventing sensitive tokens or blacklisted commands from writing to disk. Includes shortcuts (`,` and `,,`) for running Nix shells. Zellij, Foot, and Tmux are pre-styled with Catppuccin themes.

### 6. AI Stack & MCP Infrastructure
* **Ivy Bridge Llama.cpp (`modules/ai/llama.nix`)** — Overrides the `llama-cpp` package to compile a localized build, disabling AVX2 and FMA (unsupported by Ivy Bridge CPUs) while target-optimizing with `-march=ivybridge`.
* **Declarative MCP Setup (`modules/ai/mcp.nix`)** — Provisions native Model Context Protocol servers (`nixos`, `tavily`, `github`, `server-memory`, etc.) for Gemini/Antigravity CLI. Wraps credential-heavy servers inside `exec` bash structures to avoid secret leakage in `/nix/store`, and uses a post-link activation script (`setupMcpConfig`) to dynamically merge Cloudflare tokens via `jq`.
* **LLM Engine & Web UI** — Integrates Ollama and Open WebUI services, binding their systemd lifecycles (`bindsTo` / `wants`) so starting Ollama automatically launches the Web UI. Disables rebuild-induced service restarts (`restartIfChanged = false`).

### 7. Services & Cloud Backups
* **DPI Bypass (`modules/services/networking/zapret.nix`)** — Deploys the Zapret engine with split-packet mode (`--dpi-desync=split2`). Avoids iptables/nftables conflicts by disabling auto-firewall rules.
* **Cloudflare WARP proxy (`modules/services/networking/cloudflare-warp.nix`)** — Runs `wireproxy` SOCKS5 proxy on port `40000` with automated profile generation (`wgcf register`), state persistence via `StateDirectory`, and TCP keep-alive injection.
* **Secure DNS (`modules/services/networking/dns.nix`)** — Bypasses systemd-resolved, mapping DNS queries to `dnscrypt-proxy` resolving via NextDNS. Generates authenticated configurations dynamically from secrets.
* **Hourly Snapper Snapshots (`modules/services/scheduling/snapper.nix`)** — Automates Btrfs snapshots of the `/persist` directory. Timeline cleanups are scheduled at hourly marks (`OnCalendar = "*-*-* *:30:00"`) to avoid space issues.
* **SSD TBW/TBR Tracker (`modules/services/scheduling/ssd-monitor.nix`)** — Triggers an hourly script tracking SSD read/write bytes since boot (incorporating a custom LBA multiplier for MidasForce SATA drives). Spawns a Python helper (`cgroup-monitor.py`) crawling cgroup namespaces to identify top I/O consumers.
* **Restic Backups (`modules/services/restic.nix`)** — Daily encrypted backups sent to a cloud repository using an isolated rclone wrapper proxy that forces traffic through WARP. Features on-demand backups mounting (`restic-mount`) via FUSE.
* **Btrfs NoCOW Automation (`modules/services/tmpfiles.nix`)** — Automatically disables copy-on-write (`+C`) on system databases (Docker, Waydroid, Nix DBs) and user caches (browser cache, AyuGram tdata) to avoid write amplification.

---

## 🛠️ CLI Utilities & Custom Scripts

This configuration provides a custom suite of terminal tools to manage connections, updates, and system debugging:

*   **`vpn-on` / `vpn-switch` / `vpn-off`** — Decrypts ProtonVPN configs, strips default DNS blocks, injects custom NextDNS resolvers, and boots `wireproxy` on port 1080.
    *   *Paranoid Auditing*: Connections run automatic IP leak checks and DNS ASN audits. If the script detects the physical ISP's ASN, it terminates the VPN process immediately to prevent data leakage.
*   **`nfui` (Nix Flake Update Interactive)** — Interactive CLI wrapping `nix flake update`. Provides an `fzf` multi-select menu allowing users to pin-point which inputs to update, automatically reverting unselected input hashes using `jq` edits against a lock backup.
*   **`ollama-to-llama`** — Translates local Ollama models and their Modelfile parameters (system prompts, context, temperature, penalties) into matching `llama-cli` flags, launching them directly using the local GGUF model binaries.
*   **`show-zombie-parents`** — Queries and prints PPIDs and process details of parent processes currently holding defunct/zombie child states.
*   **`dl-lagu`** — Downloads high-quality MP3 audio files from YouTube, automatically embedding metadata, search fallbacks, and thumbnails.

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
