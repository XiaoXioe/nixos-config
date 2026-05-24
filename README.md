# ❄️ Klein Moretti's NixOS Configuration

This repository contains my modular NixOS system configuration, powered by **Nix Flakes** and **Home Manager**. It is designed for high productivity, software development, security, and experimental AI workloads.

## 🚀 Key Features

- **Nix Flakes**: Reproducible dependency management with pinned inputs.
- **Modular Architecture**: Clean separation between system modules (`modules/system`), services (`modules/services`), and user-space configurations (`modules/user`).
- **Impermanence & Rollback**: Supports ephemeral root setups (Btrfs snapshots) to maintain a pristine system state across reboots.
- **Security-First Approach**: 
  - **SOPS-Nix**: Encrypted secrets management integrated into the Nix workflow.
  - **Hardened SSH & GnuPG**: Optimized security configurations for daily use.
  - **Pentesting Suite**: Integrated collection of security and forensics tools.
- **Performance Optimization**: 
  - **Xanmod Kernel**: Low-latency kernel for improved system responsiveness.
  - **Ananicy-cpp**: Auto-nice daemon for intelligent resource management.
  - **Hardware Monitoring**: Proactive SSD health tracking (TBW) and system-wide monitoring.
- **AI Stack**: Native integration with **Ollama** and **Nullclaw** (custom/unstable) for local LLM execution.
- **Modern Desktop Environments**: Full support for **Hyprland** (dynamic tiling Wayland compositor) and **Niri** (scrollable tiling compositor).
- **Custom Workflow Scripts**: Includes a powerful `rebuild-all` wrapper to synchronize system and user configurations seamlessly.

## 📂 Directory Structure

```text
.
├── hosts/                  # Machine-specific configurations (e.g., nixos)
├── modules/                # Reusable NixOS and Home Manager modules
│   ├── system/             # System-level configurations (boot, hardware, network)
│   ├── services/           # System services (AI, monitoring, maintenance)
│   └── user/               # Home Manager modules (apps, desktop, dotfiles)
├── lib/                    # Custom Nix library for modular logic and user definitions
├── secrets/                # Encrypted secrets managed via SOPS
├── custom_shell/           # Custom utility scripts (e.g., rebuild-all wrapper)
└── flake.nix               # Main entry point for the system configuration
```

## 👤 User Customization

This configuration supports multi-user setups with granular feature toggling. User-specific features are managed in `lib/users.nix`. You can easily enable or disable:
- **Desktop Environments**: Hyprland, Niri, GNOME, KDE, etc.
- **Applications**: Brave, Firefox, Discord, Office suites, and more.
- **Development Tools**: Neovim (NVF), Git, Docker, and various compilers.
- **Gaming**: Optimized Wine, Steam, and GameMode configurations.

Changes in `lib/users.nix` are automatically propagated to the respective Home Manager profiles during the rebuild process.

## 🛠️ Installation & Usage

### 1. Clone the Repository
```bash
git clone https://github.com/username/nixos-config.git
cd nixos-config
```

### 2. Apply Configuration
Use the provided `rebuild-all` script (powered by `nh`) to manage your system:

```bash
# Rebuild both system and all user profiles
rebuild-all --all

# Rebuild NixOS system only
rebuild-all --system

# Rebuild Home Manager for a specific user
rebuild-all --user klein-moretti
```

*Note: This script wraps `nh os switch` and `nh home switch` for a more streamlined experience.*

## 🔐 Secrets Management

This repository utilizes [sops-nix](https://github.com/Mic92/sops-nix). Encrypted secrets are stored in `secrets/` and decrypted on-the-fly during system activation.

To edit secrets:
```bash
sops secrets/secrets.yaml
```

## ⚖️ License
This configuration is available under the MIT License or as specified by the repository owner.
