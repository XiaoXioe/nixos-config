{ lib }:

let
  features = import ./features { inherit lib; };

  # Type that accepts string or list of strings, coercing string to singleton list.
  # This eliminates the need for normalizeList — values are always lists after evaluation.
  strOrListOfStr = lib.types.coercedTo lib.types.str (s: if s == "" then [ ] else [ s ]) (
    lib.types.listOf lib.types.str
  );
in
{
  # Type-safe submodule for individual distrobox container configurations.
  # Provides validation, documentation, and default values for all supported keys.
  # Unknown keys will cause a type error at nix evaluation time.
  containerSubmoduleType = lib.types.submodule {
    options = features.featureOptions // {
      # ── Core container settings ─────────────────────────────────────────
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this container is enabled.";
      };

      image = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "OCI image for the container. If null, uses global default from programs.distrobox.settings.container_image_default.";
      };

      clone = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Name of an existing container to clone instead of downloading a fresh image.";
      };

      distro = lib.mkOption {
        type = lib.types.enum [
          "auto"
          "debian"
          "ubuntu"
          "arch"
          "fedora"
          "alpine"
          "opensuse"
          "void"
          "custom"
        ];
        default = "auto";
        description = "Distro type for automatic base packages, GUI/font/audio injection, and pre-init system hooks.";
      };

      deltaUpdates = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable delta updates (e.g. debdelta on Debian/Ubuntu) and inject base GUI/audio/font packages.";
      };

      distrobox = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use Distrobox container (true) or native Nix package (false).";
      };

      packages = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Packages to install inside the container via its native package manager.";
      };

      additional_packages = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Alias for packages (snake_case convention). Both are merged.";
      };

      # ── AUR packages (Arch Linux containers) ────────────────────────────
      aurPackages = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "List of AUR packages to automatically build and install via makepkg inside Arch Linux containers.";
      };

      aur = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Alias for aurPackages (short/convenience convention). Both are merged.";
      };

      # ── Pre-init hooks (with snake_case alias) ──────────────────────────
      preInitHooks = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Shell commands to run before container initialization.";
      };

      pre_init_hooks = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Alias for preInitHooks (snake_case convention). Both are merged.";
      };

      # ── Init hooks (with snake_case alias) ──────────────────────────────
      initHooks = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Shell commands to run after container initialization.";
      };

      init_hooks = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Alias for initHooks (snake_case convention). Both are merged.";
      };

      # ── App/binary exports (with snake_case aliases) ────────────────────
      exportedApps = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Desktop applications to export imperatively from container via distrobox export --app. Note: For declarative NixOS setups, prefer using xdg.desktopEntries in hmConfig instead to prevent duplicate desktop entries.";
      };

      exported_apps = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Alias for exportedApps (snake_case convention). Both are merged.";
      };

      exportedBins = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Binaries to export imperatively from container via distrobox export --bin into ~/.local/bin. Note: For declarative NixOS setups, prefer using generateHostWrapper/binName which adds wrappers to home.packages.";
      };

      exported_bins = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Alias for exportedBins (snake_case convention). Both are merged.";
      };

      exportedBinsPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Host directory for exported binary wrappers (distrobox export --bin).";
      };

      entry = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Whether to generate desktop application entries for exported applications on host.";
      };

      # ── Volumes and flags (with aliases) ────────────────────────────────
      volumes = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Volume bind-mounts (host:container[:options]).";
      };

      volume = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Alias for volumes. Both are merged.";
      };

      additionalFlags = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Additional flags passed to the container manager (podman/docker).";
      };

      additional_flags = lib.mkOption {
        type = strOrListOfStr;
        default = [ ];
        description = "Alias for additionalFlags (snake_case convention). Both are merged.";
      };

      # ── Container behavior flags ────────────────────────────────────────
      home = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Custom home directory path inside the container. E.g. ~/.local/share/distrobox-homes/<name>";
      };

      isolatedHome = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Automatically use an isolated home directory at ~/.local/share/distrobox-homes/<cId> to prevent polluting host $HOME.";
      };

      init = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run systemd/init process inside container (useful for system services or systemd containers).";
      };

      pull = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to pull the latest image during assemble.";
      };

      nvidia = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable NVIDIA GPU passthrough into the container.";
      };

      root = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run container in rootful mode.";
      };

      replace = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Replace existing container with the same name on assemble.
          WARNING: Setting this to true will delete and recreate the container on every
          NixOS rebuild that changes containers.ini, causing the image to be re-downloaded.
          Leave as false (default) — distrobox-assemble will skip creation if the container
          already exists with the correct image.
        '';
      };

      startNow = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Start the container immediately after creation.";
      };

      start_now = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Alias for startNow (snake_case convention). The effective value is (startNow || start_now). Setting either one to true starts the container immediately after creation.";
      };

      # ── Native package fallback options ─────────────────────────────────
      nativePkgs = lib.mkOption {
        type = lib.types.anything;
        default = null;
        description = "Native Nix package(s) to install when distrobox mode is disabled.";
      };

      package = lib.mkOption {
        type = lib.types.anything;
        default = null;
        description = "Alias for nativePkgs (single package shorthand).";
      };

      native = lib.mkOption {
        type = lib.types.anything;
        default = { };
        description = "Native package configuration attrset (with optional .package key).";
      };

      binName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Binary name for the host-side Nix wrapper script.";
      };

      env = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.either lib.types.str (lib.types.either lib.types.bool lib.types.int)
        );
        default = { };
        description = "Environment variables passed into the container and host wrapper scripts.";
      };

      binArgs = lib.mkOption {
        type = lib.types.either (lib.types.nullOr lib.types.str) (lib.types.attrsOf lib.types.str);
        default = null;
        description = "Default arguments appended to the binary execution (single string or attrset per-binary).";
      };

      generateHostWrapper = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Generate Nix writeShellScriptBin wrappers in home.packages for exported binaries.";
      };

      # ── Home Manager program integration ────────────────────────────────
      hmProgram = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Home Manager programs.<name> identifier.";
              };
              binName = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Binary name inside container for wrapper script.";
              };
              packagePath = lib.mkOption {
                type = lib.types.str;
                default = "package";
                description = "Option key under programs.<name> for package override (default 'package').";
              };
              package = lib.mkOption {
                type = lib.types.anything;
                default = null;
                description = "Explicit package override for container mode. If null and useDistrobox is true, uses null or generated wrapper.";
              };
              passWrapperAsPackage = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether to pass the generated Distrobox wrapper script as the HM programs.<name>.package instead of null (when package is null).";
              };
              extraConfig = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = { };
                description = "Extra configuration attributes merged into programs.<name>.";
              };
            };
          }
        );
        default = null;
        description = "Home Manager programs.<name> integration config.";
      };

      # ── Escape hatch ────────────────────────────────────────────────────
      extraConfig = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = "Additional freeform configuration merged directly into the container definition for distrobox-assemble.";
      };
    };
  };
}
