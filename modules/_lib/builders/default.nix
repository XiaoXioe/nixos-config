# Builder functions for NixOS configurations.
# Extracted from flake.nix to keep the entry point clean.
{
  lib,
  inputs,
  selfLib,
  system,
  flakeRoot,
  ...
}:

let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [ ];
  };

  # NixOS configurations builder
  mkNixosConfiguration =
    hostName:
    let
      userData = import (flakeRoot + "/modules/hosts/${hostName}/users") { inherit lib; };
      adminUser = userData.userName;
      flakePath = "/home/${adminUser}/nixos-config";

      baseArgs = {
        inherit
          inputs
          selfLib
          hostName
          flakePath
          userData
          ;
        userName = adminUser;
        inherit (userData) fullName;
        userFeatures = userData.userFeatures or { };
      };

      homeModules = [
        (flakeRoot + "/modules/hosts/${hostName}/home")
        inputs.nix-index-database.homeModules.nix-index
      ]
      ++ lib.optionals (inputs ? noctalia) [
        inputs.noctalia.homeModules.default
      ];

      commonModules = [
        (flakeRoot + "/modules/hosts/${hostName}")
        (flakeRoot + "/modules")
        inputs.preservation.nixosModules.preservation
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = baseArgs;
            backupFileExtension = "hm-bak";
            users.${adminUser} = {
              imports = homeModules;
            };
          };
        }
      ];
    in
    lib.nixosSystem {
      inherit system;
      specialArgs = baseArgs;
      modules = commonModules ++ [
        {
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };

  # Pre-commit / CI quality gate shell hook generator
  preCommitCheck = inputs.git-hooks.lib.${system}.run {
    src = flakeRoot;
    hooks = {
      nixfmt.enable = true;
      statix.enable = true;
      deadnix = {
        enable = true;
        settings = {
          noLambdaArg = true;
          noLambdaPatternNames = true;
        };
      };
    };
  };

  # DevShell builder
  mkDevShell = pkgs.mkShell {
    packages = with pkgs; [
      nixfmt
      statix
      deadnix
      nix-output-monitor
      nvd
    ];

    shellHook = preCommitCheck.shellHook + ''
      echo "❄️ NixOS Config DevShell"
      echo "  Tools: nixfmt, statix, deadnix, nom, nvd"
      echo "  Gate:  nixfmt + deadnix (pre-commit hook aktif)"
      echo "  Usage: nixfmt <file>     # format .nix files"
      echo "         statix .          # lint Nix code (advisory)"
      echo "         deadnix .         # find dead code"
    '';
  };
in
{
  inherit
    mkNixosConfiguration
    mkDevShell
    preCommitCheck
    pkgs
    ;
}
