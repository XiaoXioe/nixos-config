{
  config,
  lib,
  selfLib,
  pkgs,
  ...
}:

let
  distroboxHelper = import ../../_lib/modules/distrobox-helper { inherit lib; };
in
selfLib.mkModule {
  name = "virtualisation.podman";
  description = "Podman OCI container backend and Distrobox container engine configuration";

  options = {
    defaultDistroboxImage = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/library/debian:testing";
      description = "Single source of truth for the default base OCI image used by Distrobox containers across modules.";
    };

    autoUpdate = {
      enable = lib.mkEnableOption "automatic periodic updates for Distrobox containers";
      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "Systemd OnCalendar schedule expression for Distrobox container auto-updates.";
      };
    };

    pruneOrphanContainers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically delete unmanaged / orphan Distrobox containers that are no longer declared in NixOS configuration.";
    };
  };

  nixosConfig =
    let
      declaredContainers = builtins.attrNames (
        config.home-manager.users.${config.my.user.name}.programs.distrobox.containers or { }
      );
      distroboxPruneScript = distroboxHelper.mkDistroboxPruneScript {
        inherit pkgs declaredContainers;
      };

      storageConfig = import ./storage.nix { inherit config lib pkgs; };
      servicesConfig = import ./services.nix {
        inherit
          config
          lib
          pkgs
          distroboxPruneScript
          ;
      };
    in
    lib.mkMerge [
      storageConfig
      servicesConfig
      {
        environment.systemPackages = [
          pkgs.distrobox
          distroboxPruneScript
        ];
      }
    ];

  hmConfig =
    hmOpts:
    let
      declaredContainers = builtins.attrNames (hmOpts.config.programs.distrobox.containers or { });
      distroboxPruneScript = distroboxHelper.mkDistroboxPruneScript {
        inherit pkgs declaredContainers;
      };
    in
    import ./distrobox.nix {
      inherit
        config
        lib
        pkgs
        hmOpts
        distroboxPruneScript
        ;
    };
}
