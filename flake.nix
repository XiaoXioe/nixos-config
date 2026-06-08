{
  description = "Klein Moretti's NixOS Flake Configuration";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-26.05";

    custompkgs = {
      url = "github:XiaoXioe/nix-custompkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # custompkgs = {
    #   url = "path:/home/klein-moretti/nix-custompkgs";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    custompkgs-priv = {
      url = "github:XiaoXioe/nix-custompkg-priv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ ... }:
    let
      lib = inputs.nixpkgs.lib;
      hostName = "KleinMoretti";
      flakePath = "/home/klein-moretti/nixos-config";
      system = "x86_64-linux";
      adminUser = "klein-moretti";

      # User data & custom library
      allUsers = (import ./lib/users.nix).users;
      selfLib = import ./lib { inherit lib; };

      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Shared arguments for both NixOS and Home Manager
      baseArgs = {
        inherit
          inputs
          selfLib
          hostName
          flakePath
          allUsers
          ;
      };

      # Merge baseArgs with host-specific arguments
      commonSpecialArgs = baseArgs // {
        userName = adminUser;
        fullName = allUsers.${adminUser}.fullName;
      };

      homeModules = [
        ./hosts/nixos/home.nix
        ./modules/home
      ];

      commonModules = [
        ./hosts/nixos
        ./modules/system
        inputs.preservation.nixosModules.preservation
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-index-database.nixosModules.nix-index
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = baseArgs;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.users = lib.genAttrs (builtins.attrNames allUsers) (name: {
            imports = homeModules;
            _module.args = {
              userName = name;
              fullName = allUsers.${name}.fullName;
              userFeatures = allUsers.${name}.userFeatures or { };
            };
          });
        }
      ];

      # Build configurations using extracted builders
      builders = import ./lib/builders.nix {
        inherit
          lib
          inputs
          pkgs
          hostName
          adminUser
          allUsers
          selfLib
          baseArgs
          commonSpecialArgs
          homeModules
          commonModules
          ;
      };

      inherit (builders)
        mkHomeConfigurations
        mkNixosConfigurations
        ;

    in
    {
      formatter.${system} = pkgs.nixfmt;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixfmt
          statix
          deadnix
          nix-output-monitor
          nvd
        ];

        shellHook = ''
          echo "❄️ NixOS Config DevShell"
          echo "  Tools: nixfmt, statix, deadnix, nom, nvd"
          echo "  Usage: nixfmt <file>     # format .nix files"
          echo "         statix .          # lint Nix code"
          echo "         deadnix .         # find dead code"
        '';
      };

      nixosConfigurations = mkNixosConfigurations;
      homeConfigurations = mkHomeConfigurations;

      packages.${system} = import ./packages-export.nix {
        nixosConfigs = mkNixosConfigurations;
        homeConfigs = mkHomeConfigurations;
        inherit hostName adminUser;
      };
    };
}
