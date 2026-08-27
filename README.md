<div align="center"><img src=".assets/logo_nixos.png" width="320" alt="NixOS Configuration Logo"></div>
<h1 align="center">Klein Moretti's NixOS Configuration</h1>

<div align="center">

![nixos](https://img.shields.io/badge/NixOS-26.05-24273A.svg?style=flat&logo=nixos&logoColor=CAD3F5)
![kernel](https://img.shields.io/badge/kernel-CachyOS%20BORE%20%7C%20Zen-informational.svg?style=flat&logo=linux&logoColor=f4dbd6&colorA=24273A&colorB=b7bdf8)
![wayland](https://img.shields.io/badge/compositor-Niri%20%7C%20Hyprland-informational.svg?style=flat&logo=wayland&logoColor=eed49f&colorA=24273A&colorB=91d7e3)
![shells](https://img.shields.io/badge/desktop%20shell-Noctalia%20%7C%20DMS-informational.svg?style=flat&logo=gnome&logoColor=a6da95&colorA=24273A&colorB=8aadf4)
![rust](https://img.shields.io/badge/security-sudo--rs%20%2B%20sops-informational.svg?style=flat&logo=rust&logoColor=f5a97f&colorA=24273A&colorB=f5a97f)
![ai](https://img.shields.io/badge/AI%20Stack-Antigravity%20%7C%20MCP%20%7C%20Llama.cpp-informational.svg?style=flat&logo=openai&logoColor=c6a0f6&colorA=24273A&colorB=eed49f)

</div>

Modular, declarative NixOS flake featuring Home Manager integration, an ephemeral root with Btrfs impermanence, dual-kernel performance (CachyOS BORE & Linux Zen), direct Hydra binary closure ingestion (`ncp`), native upstream application packaging (`mkNativeApp`), memory-safe privilege escalation (`sudo-rs` + `auth-agent`), encrypted secrets management via `sops-nix`, a customized local AI/MCP stack, and a rich suite of custom CLI terminal utilities.

---

## 🏗️ Architecture

```text
.
├── flake.nix                    # Entry point — inputs, outputs, system wiring, devShells, checks
└── modules/
    ├── _lib/                    # Custom Nix library engine:
    │   ├── apps-versions.nix    # Single source of truth for upstream native app releases
    │   ├── cache-pins.nix       # Single source of truth for Hydra binary cache store paths
    │   ├── browser-addons/      # Firefox/Zen/Tor/Chromium policy-locks and addon builders
    │   ├── builders/            # mkNixosConfiguration builder extracted from flake.nix
    │   ├── modules/
    │   │   ├── fetchNixCache/   # Pure builtins.fetchClosure binary ingestion engine
    │   │   ├── mkModule/        # Unified builder with co-located preservation schema
    │   │   └── mkNativeApp/     # nix-ld universal wrapper for .deb/.tar.*/.snap/.AppImage
    │   └── shell/               # mkApp and mkShellCompletions wrappers
    ├── ai/                      # AI stack & tools:
    │   ├── agents/              # agy-profile, agy-ide-profile, auth-agent GUI escalation
    │   ├── interfaces/          # Open-WebUI integration
    │   ├── runtimes/            # Ivy Bridge optimized llama.cpp, ollama, ollama-to-llama
    │   └── tools/               # MCP server suite (11+ modular servers), Kaggle, Opencode
    ├── apps/                    # User application modules:
    │   ├── browsers/            # Zen Browser, Chromium, Brave, LibreWolf, Tor Browser, PSD
    │   ├── custom/              # Freqtrade crypto bot engine, video scrapers, TradingView
    │   ├── dev/                 # Development stack:
    │   │   ├── nix/             # cache-pins (ncp), apps-updater (unau), nfui, nh, cek-cache
    │   │   ├── system/          # Android SDK/ADB, Dolphin/Nemo file managers, languages
    │   │   └── vcs/             # Git, multi-account GitHub CLI (gh), Conventional Commits
    │   ├── editors/             # VSCodium (declarative extensions), Zed Editor, Neovim
    │   ├── gaming/              # RetroArch (20+ cores), Dolphin Emu, PCSX2, PPSSPP, Wine, Steam
    │   ├── media/               # MPD + rmpc + Cava, MPV (uosc), yt-dlp, gallery-dl, dl-lagu
    │   ├── office/              # Obsidian, Betterbird/Thunderbird, Proton Mail, Zathura
    │   ├── social/              # Materialgram, Discord, Signal
    │   └── terminal/            # Foot, Alacritty, Kitty, Wezterm, Zellij, Fish, Starship, utils
    ├── core/                    # System core:
    │   ├── bootloader.nix       # GRUB2 EFI + catppuccin theme + Grub2 File Manager (grubfm)
    │   ├── graphics.nix         # Crocus/i965 VA-API hardware acceleration & DDC/CI monitor
    │   ├── kernel/              # CachyOS BORE scheduler & Linux Zen kernel configurations
    │   ├── memory.nix           # Zram swap (zstd), /tmp tmpfs, VM swappiness tuning
    │   ├── nix.nix              # Binary caches, build limits, SOCKS5 proxy routing
    │   └── pipewire/            # PipeWire audio engine, Perfect EQ, and AutoGain effects
    ├── desktop/                 # Desktop Managers, Compositors & Shells:
    │   ├── de/                  # GNOME, KDE Plasma, XFCE debloated configurations
    │   ├── greeter.nix          # SDDM (Astronaut theme Wayland/KWin), DMS-Greeter, GDM
    │   ├── hyprland/            # Hyprland tiling compositor with UWSM integration
    │   ├── niri/                # Niri scrollable-tiling compositor & keybindings
    │   ├── shells/              # Noctalia v5 native Wayland shell & DankMaterialShell (DMS)
    │   ├── theme.nix            # Colloid-Dark, Vimix-white-cursors, Tela-circle-dark
    │   └── tools/               # Wayland desktop tools (OCR scanner, QR scanner, Satty)
    ├── hardware/                # Hardware mounting and Btrfs root preservation
    ├── hosts/                   # Host-specific configurations (KleinMoretti)
    ├── security/                # Security layer:
    │   ├── auth/                # sudo-rs memory-safe escalation, sudo, doas, rtkit
    │   ├── compat.nix           # nix-ld binary compatibility with 80+ host libraries
    │   ├── gnupg/               # Declarative GPG keys, auto-imported private keys & passphrase
    │   ├── hardening.nix        # Kernel sysctl hardening, AppArmor, Firejail
    │   ├── networking.nix       # Nftables firewall, auto-killswitch dispatcher
    │   ├── password-manager.nix # Bitwarden, Proton Pass, Ente Auth
    │   └── secrets.nix          # Sops-nix age encryption using host SSH key
    ├── services/                # Background daemons & scheduled services:
    │   ├── boot-speedup.nix     # Optimization masks for slow daemons and fast shutdown
    │   ├── documents/           # Stirling-PDF local service + MCP endpoint
    │   ├── networking/          # Zapret2 (Lua DPI bypass), Cloudflare WARP, VPN, DNSCrypt
    │   ├── scheduling/          # Ananicy-cpp auto-nice, Snapper Btrfs snapshots, SSD monitor
    │   ├── storage/             # Btrfs NoCOW migration, Restic domain backups, Rclone proxy
    │   └── vaultwarden.nix      # Local Vaultwarden server with Caddy HTTPS reverse proxy
    └── specialization/          # Daily mode and Retro Gaming performance specializations
```

---

## 🛠️ Key Features & Technical Details

### 1. System Core & Unified Module Architecture
* **Single Source of Truth (`modules/hosts/KleinMoretti/users/`)** — System capabilities and user suites are toggled per-host under `userFeatures`. The custom `selfLib.mapFeatures` transformer maps these flat flags into deep nested attribute paths.
* **Unified Module Builder (`selfLib.mkModule`)** — Consolidates system options, Home Manager config (`hmConfig`), and co-located Btrfs preservation rules (`preservation`) into a single boilerplate-free module definition.
* **Bootloader (`modules/core/bootloader.nix`)** — GRUB2 with full EFI support, styled with `catppuccin-grub` (Macchiato). Features an automated chainloader entry and custom binary build for **Grub2 File Manager** (`grubfmx64.efi`) directly from the EFI partition.
* **Dual-Kernel Support (`modules/core/kernel/`)** — Boots the high-performance **CachyOS Kernel with BORE Scheduler** (`linuxPackages-cachyos-bore` from `nix-cachyos-kernel`), with an integrated fallback toggle for the **Linux Zen Kernel** (`linuxPackages_zen`). Applies hardware workarounds for Intel Ivy Bridge graphics (disabling i915 FBC/PSR) and tunes TCP congestion control with CAKE (`sch_cake`) and BBR (`tcp_bbr`).
* **Memory & Swap Tuning (`modules/core/memory.nix`)** — Zram swap with 100% RAM allocation using `zstd` compression. Mounts `/tmp` on a RAM-backed tmpfs (capped at 60%), mounts Nix build cache on dedicated tmpfs, and tunes VM swappiness (`vm.swappiness = 180`) and dirty page writeback timers to minimize SSD wear.
* **Nix Daemon Hardening (`modules/core/nix.nix`)** — Multi-source binary caches (NixOS, nix-community, Cachix, Niri, Hyprland, Noctalia, Attic). Injects GitHub tokens via SOPS secrets to raise API rate limits.

---

### 2. Transient Root & Declarative Btrfs Preservation
* **Ephemeral Wiping (`modules/hardware/preservation.nix`)** — Mounts and wipes the Btrfs subvolumes `@nixos-root` and `@nixos-home` during the early initrd stage on every boot.
* **Rollback Snapshots & Retention** — Before wiping, old roots and homes are archived with timestamps (`@nixos-old-roots/root-$timestamp` and `@nixos-persist/home-snapshots/$timestamp`). A background cleanup service (`preservation-cleanup.service`) safely retains the last 20 roots and snapshots.
* **Declarative Preservation** — Powered by `preservation` under `/persist`. Modules declare directory and file persistence co-located within their own definitions (`preservation = { userDirectories = [ ... ]; systemDirectories = [ ... ]; };`).

---

### 3. Binary Ingestion & Native App Compatibility
* **Direct Nix Binary Cache Ingestion (`fetchCachePinned` / `cache-pins.nix`)**:
  * Ingests pre-built store paths directly from Hydra/cache.nixos.org via `builtins.fetchClosure`.
  * **Zero nixpkgs evaluation overhead** and **Zero Re-Download/Re-Unpack** (paths are immutable in `/nix/store`).
  * Managed interactively via the **`ncp` (`nix-cache-pin`)** CLI and TUI.
* **Universal Native App Builder (`selfLib.mkNativeApp` / `apps-versions.nix`)**:
  * Wraps official upstream binary packages (`.deb`, `.tar.*`, `.snap`, `.AppImage`) using `nix-ld` host libraries.
  * Eliminates heavy build times for desktop apps (LibreWolf, Discord, Materialgram, Obsidian, Betterbird, TradingView, Zed, Wine, TDL).
  * Automatically pins all active application source archives to system GC Roots (`system.extraDependencies`) to prevent accidental garbage collection.
  * Version updates are managed interactively via **`unau` (`update-native-apps`)**.

---

### 4. Privilege Escalation & Security
* **Memory-Safe Escalation (`modules/security/auth/`)** — Replaces standard sudo with the memory-safe Rust implementation **`sudo-rs`** (`security.sudo-rs.enable = true`), restricting execution strictly to the wheel group and enforcing pre-computed NOPASSWD whitelists.
* **AI Agent GUI Escalation (`auth-agent`)** — Enables AI agents running in sandboxed environments (`no new privileges`) to execute root tasks safely via an SSH loopback session that triggers a Zenity GUI prompt or checks a time-bounded cached token (`cache-confirm`, `cache-notify`, `strict`, `session-auto`).
* **Secrets Management (`modules/security/secrets.nix`)** — Decrypts API tokens, SSH keys, binary secrets, and VPN configurations via `sops-nix` using the system's SSH host key. Hashed user passwords are dynamically injected without writing plaintext to disk.
* **Declarative GPG Keyring (`modules/security/gnupg/`)** — Manages public keys, encrypted private keys, and passphrases declaratively. Automatically imports private keys into the GPG daemon keyring and pre-loads passphrases into `gpg-agent` cache on session startup.

---

### 5. Desktop Compositors, Shells & Wayland Tools
* **Niri Compositor (`modules/desktop/niri/`)** — Scrollable tiling Wayland compositor configured with custom layout rules, window animations, keybinds, and IPC integrations.
* **Hyprland Compositor (`modules/desktop/hyprland/`)** — Dynamic tiling compositor integrated with UWSM (`withUWSM = true`).
* **Modern Wayland Shells (`modules/desktop/shells/`)**:
  * **Noctalia v5** — Native Wayland desktop shell providing unified status bars, notifications, and control centers for Niri and Hyprland.
  * **DankMaterialShell (DMS)** — Material Design shell integration.
* **Display Managers & Greeters (`greeter.nix`)** — Flexible greeter backend supporting **SDDM** (with `sddm-astronaut` theme and Wayland/KWin), **DMS-Greeter**, or **GDM**.
* **Wayland Productivity Tools (`desktop.tools`)**:
  * `wayland-scan-ocr` — High-precision on-screen OCR scanner powered by ImageMagick preprocessing and Tesseract OCR (`--psm 6`).
  * `wayland-scan-qr` — Instant QR Code and Barcode scanner using `zbarimg`.
  * `wayland-scan-annotate` — Interactive screen capture and annotation tool using `satty`.

---

### 6. Local AI Ecosystem & Multi-Model MCP
* **Antigravity Profile Launchers (`modules/ai/agents/`)**:
  * `agy-profile` — Multi-account profile launcher for Google Antigravity CLI with Bubblewrap sandbox isolation.
  * `agy-ide-profile` — Multi-account launcher for Antigravity IDE with isolated `XDG_RUNTIME_DIR` and automatic SQLite token patching.
* **Optimized Llama.cpp (`modules/ai/runtimes/llama.nix`)** — Custom build targeting Intel Ivy Bridge CPUs (`-march=ivybridge`, AVX/F16C enabled, AVX2/FMA disabled) to prevent `Illegal Instruction` crashes.
* **Declarative MCP Suite (`modules/ai/tools/mcp/`)** — Auto-discovers and provisions Model Context Protocol servers for Antigravity CLI and OpenCode:
  * `ai-memory` (systemd user daemon with web UI & OpenAI-compatible LLM endpoint)
  * `search` (`free-search-mcp` multi-engine search & research)
  * `scrapling` (headless browser scraping via declarative Chromium)
  * `mcp-nixos` (NixOS option search & documentation)
  * `codebase-memory-mcp`, `google-colab-mcp`, `telegram-mcp`, `cloudflare-api`, `stirling-pdf`
  * Wrapped inside `mcpWrapper` for graceful termination signal handling (`SIGTERM`/`SIGINT`).
* **Ollama & Open WebUI** — Lifecycle-coupled local LLM runtimes with `ollama-to-llama` conversion utility.

---

### 7. Network, Privacy & Anti-DPI
* **Zapret2 DPI Bypass (`modules/services/networking/zapret.nix`)** — Deploys Zapret2 v2.x with Lua scripting engine (`nfqws2`), split-packet strategies, and automatic detection of fake TLS/HTTP binary blobs.
* **Cloudflare WARP Proxy (`modules/services/networking/cloudflare-warp.nix`)** — Runs `wireproxy` SOCKS5 proxy on port `40000` with automated in-memory WGCF account generation and TCP keep-alive injection.
* **ProtonVPN WireGuard Stack (`modules/services/networking/vpn.nix`)** — Multi-profile WireGuard client running `wireproxy` (SOCKS5 on port `1080`, HTTP on port `1081`). Decrypts configs in RAM (`/dev/shm`) and injects authenticated NextDNS resolvers.
* **Secure DNS (`modules/services/networking/dns.nix`)** — `dnscrypt-proxy` resolving via NextDNS with Quad9 fallback, DNSSEC enforcement, IPv6 blocking, and local monitoring UI on port `4200`.
* **NetworkManager Killswitch (`modules/security/networking.nix`)** — Automated nftables dispatcher script that drops physical interface outbound traffic whenever a VPN connection is active.

---

### 8. Storage Optimization, Resiliency & Backups
* **Btrfs NoCOW Migration (`modules/services/storage/btrfs-nocow-migration.nix`)** — Automatically disables Copy-on-Write (`+C`) on system databases (Docker, Waydroid, Nix DB) and user caches (browser caches, Materialgram tdata) to prevent write amplification.
* **Domain-Separated Restic Backups (`modules/services/storage/restic.nix`)** — Scheduled cloud backups via Rclone, isolated into 3 distinct domains:
  1. `vaultwarden` — Zero-downtime online SQLite backups every 3 hours.
  2. `system-config` — Nix configurations, SSH host keys, and system states.
  3. `user-data` — User documents, credentials, gnupg, and persistent directories.
  * Routes all backup traffic through Cloudflare WARP proxy and provides on-demand FUSE mounting (`restic-mount`).
* **SSD TBW Tracker (`modules/services/scheduling/ssd-monitor.nix`)** — Hourly tracking of SSD read/write bytes with a Python helper (`cgroup-monitor.py`) crawling cgroups to detect top I/O consumers.
* **Local Vaultwarden Server (`modules/services/vaultwarden.nix`)** — Self-hosted password manager with automated local Caddy HTTPS reverse proxy and build-time self-signed certificates.

---

## 🛠️ CLI Utilities & Custom Scripts

| Command | Description |
| :--- | :--- |
| **`ncp`** / `nix-cache-pin` | Unified Nix Binary Cache manager: `query`, `fetch` (via aria2c), `update`, `audit`, `adopt`, `stats`, `diff`, `tree`, `search`, `delete`, and `tui`. |
| **`unau`** / `update-native-apps` | Interactive upstream version updater for `apps-versions.nix` using `gh`, `fzf`, and `nixfmt`. |
| **`nfui`** | Interactive Flake updater with `fzf` multi-select and rollback recovery from `.nfui-lock.bak`. |
| **`auth-agent`** | Secure GUI-based root privilege escalation helper with token caching (`--status`, `--lock`, `<cmd>`). |
| **`agy-profile`** | Multi-account launcher for Google Antigravity CLI using Bubblewrap sandbox isolation. |
| **`agy-ide-profile`** | Multi-account launcher for Antigravity IDE with SQLite credential management. |
| **`vpn-on`** / **`vpn-switch`** / **`vpn-off`** | Wireproxy ProtonVPN controller with interactive profile picker, RAM decryption, and NextDNS injection. |
| **`ambil`** / **`kirim`** | Remote file transfer scripts (SSH/SCP) with host autocompletion for Fish, Bash, and Zsh. |
| **`wayland-scan-ocr`** | On-screen OCR text recognition tool copying results directly to clipboard. |
| **`wayland-scan-qr`** | Instant QR Code / Barcode scanner for Wayland desktops. |
| **`wayland-scan-annotate`**| Interactive screenshot capture and annotation utility with Satty. |
| **`dl-lagu`** | High-quality YouTube audio/music downloader with automated metadata and thumbnail embedding. |
| **`softsub`** | Fast subtitle muxer merging `.srt` files into `.mp4` or `.mkv` without video re-encoding. |
| **`wayres`** | Resolution and density switcher for Waydroid Android sessions (`portrait`, `auto`). |
| **`mpv-wrapper`** | MPV launcher with YouTube resolution override (`-r 1080`, `-r 480`) and AVC priority. |
| **`show-zombie-parents`** | Inspects and displays process details of parents holding defunct/zombie processes. |
| **`cek-cache`** | Verifies and inspects Nix binary signatures for store paths in `/nix/store`. |
| **`gcfeat`**, **`gcfix`**, **`gcchore`**... | Conventional Commits shortcuts wrapping `git commit -m "<type>: <message>"`. |

---

## 🧩 Developer Guide

### 1. Module Convention (`selfLib.mkModule`)
Every feature module uses `selfLib.mkModule` to automatically register `options.my.<name>.enable`, wire NixOS and Home Manager configs, and register co-located preservation rules:

```nix
{ pkgs, selfLib, ... }:

selfLib.mkModule {
  name        = "apps.office.example";   # dot-path → options.my.apps.office.example.enable
  description = "Example office application";

  nixosConfig = { ... };                 # System-level config (active when enable = true)
  hmConfig    = hmOpts: { ... };         # Home Manager config (receives hmOpts.config, hmOpts.osConfig)
  preservation = {
    userDirectories = [ ".config/example" ];
    directories     = [ "/var/lib/example" ];
  };
}
```

### 2. Nix Binary Cache Ingestion (`ncp` & `cache-pins.nix`)
To use a package directly from the Nix binary cache without nixpkgs evaluation overhead:
```bash
# Add or adopt a package into cache-pins.nix
ncp adopt rclone
# Update existing pins
ncp update --all -w
```
Reference in Nix modules:
```nix
environment.systemPackages = [
  (selfLib.fetchCachePinned "rclone")
];
```

### 3. Native App Version Pinning (`unau` & `apps-versions.nix`)
To add or update an upstream binary (.deb, .tar.*, .snap, .AppImage):
```bash
# Update versions interactively via GitHub CLI & fzf
unau
```
Declare in Nix modules:
```nix
let
  appInfo = selfLib.appVersions.obsidian;
  obsidianNative = (selfLib.mkNativeApp pkgs) {
    name     = "obsidian";
    inherit (appInfo) version;
    src      = selfLib.fetchApp pkgs "obsidian";
    execPath = "opt/Obsidian/obsidian";
    binName  = "obsidian";
  };
in { ... }
```

### 4. Feature Toggles (`userFeatures`)
All system and user features are toggled in [`modules/hosts/KleinMoretti/users/features/`](file:///home/klein-moretti/nixos-config/modules/hosts/KleinMoretti/users/features/):
```nix
userFeatures = {
  apps = {
    browsers.zen = true;
    editors.vscodium = true;
  };
  core.kernel.cachyos = true;
  desktop.niri.enable = true;
};
```

### 5. Web App (PWA) Helper (`selfLib.mkWebApp`)
Create a desktop launcher and Chromium/Brave web application wrapper:
```nix
home.packages = [
  (selfLib.mkWebApp pkgs {
    name        = "my-app";
    desktopName = "My Web App";
    url         = "https://app.example.com";
    browser     = "chromium";
    icon        = "chromium";
  })
];
```

### 6. Secrets Management
Secrets are encrypted using `sops-nix`. To edit or view secrets:
```bash
sops modules/security/secrets.yaml
```

---

## 💻 Quick Start & Verification

```bash
# Enter development shell (nixfmt, statix, deadnix, nom, nvd)
nix develop

# Verify flake syntax and evaluation
nix flake check

# Inspect binary cache pins status
ncp stats
```

---

## ⚖️ License

MIT License.
