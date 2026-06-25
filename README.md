# ❄️ Klein Moretti's NixOS Configuration

Modular NixOS flake with Home Manager, impermanence, sops-nix, and full AI/gaming/desktop support.

## 🏗️ Architecture

```text
.
├── flake.nix                    # Entry point — inputs, outputs, wiring
├── dotfiles/                    # Direct repository dotfiles (Niri, DMS, fish, rmpc)
├── lib/
│   ├── default.nix              # Public API for custom library functions
│   ├── modules.nix              # Unified mkModule builder
│   └── builders.nix             # NixOS + Home Manager configuration builders
│
├── hosts/
│   └── nixos/
│       ├── default.nix          # Host-specific overrides & dynamic feature linking
│       ├── home.nix             # Home Manager wiring
│       ├── users.nix            # User definitions and feature flags (Single Source of Truth)
│       └── hardware-configuration.nix
│
├── modules/
│   ├── ai/                      # AI stack: Ollama, llama.cpp, Open WebUI, Antigravity CLI, & local MCP servers (mcp-nixos, codebase-memory-mcp)
│   ├── apps/                    # Home Manager applications & user settings
│   ├── core/                    # System core: boot, fonts, graphics, nix, pipewire (including metadata options)
│   ├── desktop/                 # Desktop Managers & Themes: KDE, GNOME, Niri, Hyprland
│   ├── hardware/                # Hardware-level: mounting, preservation (impermanence)
│   ├── scripts/                 # Custom CLI tools and scripts
│   ├── security/                # Security & Secrets: sops, hardening, gnupg, pentest
│   ├── services/                # System services: networking, vpn, snapper, ananicy
│   ├── settings/                # HM settings: identity, file symlinks
│   ├── specialization/          # Performance & Retro gaming modes
│   └── virtualisation/          # Docker, Waydroid, libvirt
│
├── secrets/                     # Encrypted via sops-nix (age)
│   ├── secrets.yaml             # Main secrets file
│   ├── binary/                  # Encrypted binary secrets (fastfetch-logo, foto-profile, etc.)
│   └── vpn-files/               # External VPN configuration files
│
└── packages-export.nix          # Unified export for custom derivations
```

## ✨ Key Features

- **Unified Module Builder (`mkModule`)** — Simplified syntax that handles options and config merging for both NixOS and Home Manager.
- **Single Source of Truth** — Per-user features (`hosts/nixos/users.nix`) automatically drive and map to system-wide configurations using recursive feature mapping (`mapFeatures`) in `hosts/nixos/default.nix`.
- **Nix Flakes** — Pinned inputs and reproducible builds.
- **Auto-import modules** — `scanPaths` discovers and imports new `.nix` files automatically.
- **Impermanence** — Ephemeral root with Btrfs snapshots + bind-mount persistence.
- **Secrets Management** — `sops-nix` with SSH host key for effortless decryption and dynamic user password injection.
- **AI-Ready & Declarative MCP** — Integrasi LLM lokal (Ollama, llama.cpp, Open WebUI) yang dioptimalkan untuk perangkat keras, dikombinasikan dengan lingkungan agen pengkodean (Antigravity CLI, Claude Code) dan server Model Context Protocol (MCP) terintegrasi secara native (seperti `mcp-nixos` dengan dukungan saluran `26.05`).

## 🛠️ Quick Start

```bash
# Enter devShell (formatters + linters available)
nix develop
```

## 🧩 User Feature Mapping (The Core Logic)

The core logic of this configuration centers around `hosts/nixos/users.nix`. Instead of toggling features manually per-host, you enable features explicitly per-user.

In `hosts/nixos/users.nix`:
```nix
{
  fullName = "Klein Moretti (admin)";
  uid = 1000;
  extraGroups = [ "wheel" "networkmanager" ];
  userFeatures = {
    desktop.niri = true;
    services.networking.dns = true;
  };
}
```

This configuration is automatically mapped in `hosts/nixos/default.nix` through a recursive helper function (`mapFeatures`) that converts flat/nested boolean configurations into the appropriate `.enable = true` structure needed by NixOS options, and merges them directly using `lib.recursiveUpdate`.

## 🧱 Unified Module Builder (`mkModule`)

All modules use the unified `selfLib.mkModule` builder. It automatically creates an `enable` option and wraps the configuration in an `mkIf` guard, cleanly handling both OS and Home Manager state in one file.

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

### Module with Options and Home Manager Integration
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
  hmConfig = { config, ... }: {
    # Home manager config applied directly to the user who enabled this module
  };
}
```

## 🔐 Secrets & Multi-User Passwords

```bash
sops secrets/secrets.yaml           # edit
sops secrets/binary/foto-profile.enc       # binary file
```
The system uses the SSH host key for decryption, so no manual key management is needed on the target machine.

**Adding New Users:**
Because `mutableUsers = false` is active, every user declared in `hosts/nixos/users.nix` must have a corresponding password hash defined in `secrets.yaml` under the key `<userName>_password_hash` (e.g., `klein-moretti_password_hash`). 

Generate a hash using:
```bash
mkpasswd -m yescrypt
```

## 💻 DevShell

`nix develop` provides: `nixfmt` (formatter), `statix` (linter), `deadnix` (dead code), `nom` / `nvd` (build output analysis).

## ⚖️ License

MIT
