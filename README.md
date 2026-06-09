# ❄️ Klein Moretti's NixOS Configuration

Modular NixOS flake with Home Manager, impermanence, sops-nix, and full AI/gaming/desktop support.

## 🏗️ Architecture

```text
.
├── flake.nix                    # Entry point — inputs, outputs, wiring
├── lib/
│   ├── default.nix              # scanPaths, forAllUsers helpers
│   ├── builders.nix             # NixOS + Home Manager builder functions
│   └── users.nix                # User definitions with feature flags
│
├── hosts/
│   └── nixos/
│       ├── default.nix          # Host-specific overrides (minimal)
│       ├── home.nix             # Maps userFeatures → home module toggles
│       └── hardware-configuration.nix
│
├── modules/
│   ├── system/                  # NixOS system modules
│   │   ├── options/             # Central option declarations
│   │   ├── core/                # Boot, locale, fonts, graphics, nix, pipewire, ...
│   │   ├── security/            # Hardening, secrets, gnupg, pentest, ...
│   │   ├── networking/          # DNS, OpenSSH, VPN, firewall
│   │   ├── services/            # Snapper, ananicy, base services, ...
│   │   ├── hardware/            # Mounting, impermanence (preservation)
│   │   ├── desktop/             # Hyprland, Niri, KDE, GNOME, steam, ...
│   │   ├── ai/                  # Ollama, llama.cpp, Open WebUI
│   │   ├── virtualisation/      # Docker, Waydroid, libvirt
│   │   ├── scripts/             # Custom CLI wrappers (rebuild-all, etc.)
│   │   └── specialisation/      # Daily, retro-gaming specialisations
│   │
│   └── home/                    # Home Manager modules
│       ├── applications/
│       │   ├── browsers/        # Brave, Firefox, LibreWolf
│       │   ├── dev/             # Git, SSH, Nemo, dev packages
│       │   ├── editors/         # Neovim (NVF), VSCodium, Zed
│       │   ├── terminal/        # Fish, Tmux, WezTerm, Starship, Fastfetch
│       │   ├── media/           # Media players, music, office, social
│       │   ├── gaming/          # Wine, game packages
│       │   ├── packages/        # User packages + pentest tools
│       │   └── custom/          # Custom packages from private repos
│       ├── desktop/             # Caelestia, DMS, GTK themes
│       ├── services/            # Rclone mount
│       ├── settings/            # Symlinks, identity
│       └── dotfiles/            # Config files (fish, hypr, niri, rmpc, ...)
│
├── secrets/                     # Encrypted via sops-nix (age)
│   ├── secrets.yaml
│   └── vpn-files/
│
└── packages-export.nix          # Exported packages (caelestia, llama, etc.)
```

## ✨ Key Features

- **Nix Flakes** — Pinned inputs, `nix flake check`, repro builds
- **Auto-import modules** — `scanPaths` discovers new `.nix` files automatically
- **Feature flags** — `lib/users.nix` controls per-user app toggles via `freeformType`
- **Impermanence** — Ephemeral root with Btrfs snapshots + bind-mount persistence
- **Secrets** — Encrypted via `sops-nix`/age, decrypted at activation
- **Multi-DE** — Hyprland, Niri, KDE Plasma, GNOME — switchable per boot
- **AI stack** — Local LLMs via Ollama + llama.cpp, Open WebUI
- **Hardened** — sudo-rs, fail2ban, GnuPG, keyring, nix-ld compat
- **Performance** — Zen kernel, BBR, zram, ananicy-cpp, Btrfs optimisations

## 🛠️ Quick Start

```bash
# Enter devShell (formatters + linters available)
nix develop

# Rebuild system + all users
rebuild-all --all

# Rebuild system only
rebuild-all --system

# Rebuild Home Manager for specific user
rebuild-all --user klein-moretti
```

## 👤 Adding a User Feature

```bash
# 1. Enable flag in lib/users.nix
userFeatures = {
  my-new-app = true;
};

# 2. Create module in modules/home/applications/<category>/
# scanPaths auto-imports it — no manual registration needed.
```

## 🔐 Secrets

```bash
sops secrets/secrets.yaml           # edit
sops secrets/foto-profile.enc       # binary file
```

Keys: `age1gktsu...` (host) + `age1yrd6...` (user).

## 💻 DevShell

`nix develop` provides: `nixfmt` (formatter), `statix` (linter), `deadnix` (dead code), `nom` / `nvd` (build output).

## ⚖️ License

MIT
