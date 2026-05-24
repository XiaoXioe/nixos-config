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
      # url = "git+ssh://git@github.com/XiaoXioe/nix-custompkg-priv.git";
      url = "github:XiaoXioe/nix-custompkg-priv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";

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
            # allowBroken = true;
            # nvidia.acceptLicense = true;
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
            inputs.preservation.nixosModules.preservation
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = baseArgs;
              # Jika HM menemukan file yang sudah ada (tidak dikelola Nix),
              # beri ekstensi backup daripada langsung gagal.
              home-manager.backupFileExtension = "hm-bak";
              home-manager.users = inputs.nixpkgs.lib.genAttrs (builtins.attrNames allUsers) (name: {
                imports = [ ./hosts/nixos/home.nix ];
                _module.args = {
                  userName = name;
                  fullName = allUsers.${name}.fullName;
                  userFeatures = allUsers.${name}.userFeatures or { };
                };
              });
            }
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

          myNixosConfigurations = {
            ${hostName} = inputs.nixpkgs.lib.nixosSystem {
              inherit pkgs;
              specialArgs = commonSpecialArgs;
              modules = commonModules ++ [
                { boot.kernelPackages = pkgs.linuxPackages_zen; }
              ];
            };
          };

        in
        {
          nixosConfigurations = myNixosConfigurations;
          homeConfigurations = mkHomeConfigurations;

          packages.${system} = import ./packages-export.nix {
            nixosConfigs = myNixosConfigurations;
            homeConfigs = mkHomeConfigurations;
            inherit hostName adminUser;
          };
        };
    };
}
