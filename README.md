# ❄️ Klein Moretti's NixOS Configuration

Modular NixOS flake with Home Manager, impermanence, sops-nix, and full AI/gaming/desktop support.

## 🏗️ Architecture

```text
.
├── flake.nix                    # Entry point — inputs, outputs, wiring
├── lib/
│   ├── default.nix              # Public API for custom library functions
│   ├── modules.nix              # Unified mkModule builder
│   ├── builders.nix             # NixOS + Home Manager configuration builders
│   └── users.nix                # User definitions and feature flags
│
├── hosts/
│   └── nixos/
│       ├── default.nix          # Host-specific overrides
│       ├── home.nix             # Home Manager wiring
│       └── hardware-configuration.nix
│
├── modules/
│   ├── ai/                      # AI stack: Ollama, llama.cpp, Open WebUI
│   ├── apps/                    # Home Manager applications & user settings
│   ├── core/                    # System core: boot, fonts, graphics, nix, pipewire
│   ├── desktop/                 # Desktop Managers & Themes: KDE, GNOME, Niri
│   ├── hardware/                # Hardware-level: mounting, preservation (impermanence)
│   ├── options/                 # Custom global option declarations
│   ├── scripts/                 # Custom CLI tools and scripts
│   ├── security/                # Security & Secrets: sops, hardening, gnupg, pentest
│   ├── services/                # System services: networking, vpn, snapper, ananicy
│   ├── settings/                # HM settings: identity, file symlinks
│   ├── specialization/          # Performance & Retro gaming modes
│   └── virtualisation/          # Docker, Waydroid, libvirt
│
├── secrets/                     # Encrypted via sops-nix (age)
│   ├── secrets.yaml             # Main secrets file
│   └── vpn-files/               # External VPN configuration files
│
└── packages-export.nix          # Unified export for custom derivations
```

## ✨ Key Features

- **Unified Module Builder (`mkModule`)** — Simplified syntax that handles options and config merging for both NixOS and Home Manager.
- **Nix Flakes** — Pinned inputs and reproducible builds.
- **Auto-import modules** — `scanPaths` discovers and imports new `.nix` files automatically.
- **Feature flags** — Per-user features toggled via `lib/users.nix`.
- **Impermanence** — Ephemeral root with Btrfs snapshots + bind-mount persistence.
- **Secrets Management** — `sops-nix` with SSH host key for effortless decryption.
- **AI-Ready** — Local LLM integration optimized for hardware.

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

## 🧩 Unified Module Builder (`mkModule`)

All modules now use the unified `selfLib.mkModule` builder. It automatically creates an `enable` option and wraps the configuration in an `mkIf` guard.

### Simple Module
```nix
{ selfLib, ... }:
selfLib.mkModule {
  name = "core.pipewire";
  nixosConfig = {
    services.pipewire.enable = true;
  };
}
```

### Module with Options
```nix
{ lib, selfLib, ... }:
selfLib.mkModule {
  name = "virtualisation.docker";
  options = {
    autoUpdate = lib.mkEnableOption "Auto-update containers";
  };
  nixosConfig = {
    virtualisation.docker.enable = true;
  };
}
```

## 🔐 Secrets

```bash
sops secrets/secrets.yaml           # edit
sops secrets/foto-profile.enc       # binary file
```
The system uses the SSH host key for decryption, so no manual key management is needed on the target machine.

## 💻 DevShell

`nix develop` provides: `nixfmt` (formatter), `statix` (linter), `deadnix` (dead code), `nom` / `nvd` (build output analysis).

## ⚖️ License

MIT
