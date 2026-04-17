{
  description = "Klein Moretti's NixOS Flake Configuration";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    custompkgs = {
      url = "github:XiaoXioe/nix-custompkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    custompkgs-priv = {
      url = "git+ssh://git@github.com/XiaoXioe/nix-custompkg-priv.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      #url = "github:nix-community/home-manager";
      url = "github:nix-community/home-manager/release-25.11";
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

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      flake =
        let
          hostName = "KleinMoretti";
          flakePath = "/home/klein-moretti/nixos-config";
          system = "x86_64-linux";
          adminUser = "klein-moretti";

          # Tarik data & library
          allUsers = (import ./lib/users.nix).users;
          selfLib = import ./lib { inherit (inputs.nixpkgs) lib; };

          nixpkgsConfig = {
            allowUnfree = true;
            permittedInsecurePackages = [ "openssl-1.1.1w" ];
          };

          pkgs = import inputs.nixpkgs {
            inherit system;
            config = nixpkgsConfig;
          };

          pkgsUnstable = import inputs.nixpkgs-unstable {
            inherit system;
            config = nixpkgsConfig;
          };

          # Variabel-variabel ini dibutuhkan oleh NixOS dan Home Manager
          baseArgs = {
            inherit
              inputs
              selfLib
              hostName
              flakePath
              pkgsUnstable
              allUsers
              ;
          };

          # Menggunakan operator // untuk menggabungkan baseArgs dengan argumen spesifik
          commonSpecialArgs = baseArgs // {
            userName = adminUser;
            fullName = allUsers.${adminUser}.fullName;
          };

          commonModules = [
            ./hosts/nixos
            ./modules
            ./custom_shell
            inputs.impermanence.nixosModules.impermanence
            inputs.sops-nix.nixosModules.sops
          ];

          # Generator Home Manager Standalone
          mkHomeConfigurations = inputs.nixpkgs.lib.listToAttrs (
            map (
              name:
              let
                user = allUsers.${name};
              in
              {
                name = "${name}@${hostName}";
                value = inputs.home-manager.lib.homeManagerConfiguration {
                  inherit pkgs;

                  extraSpecialArgs = baseArgs // {
                    userName = name;
                    fullName = user.fullName;
                    userFeatures = user.userFeatures or { };
                  };

                  modules = [ ./hosts/nixos/home.nix ];
                };
              }
            ) (builtins.attrNames allUsers)
          );

        in
        {
          nixosConfigurations = {
            ${hostName} = inputs.nixpkgs.lib.nixosSystem {
              inherit pkgs;
              specialArgs = commonSpecialArgs;
              modules = commonModules ++ [
                { boot.kernelPackages = pkgs.linuxPackages_xanmod; }
              ];
            };
          };

          homeConfigurations = mkHomeConfigurations;
        };
    };
}
