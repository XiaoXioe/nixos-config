{
  description = "Klein Moretti's NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-26.05";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # custompkgs = {
    #   url = "github:XiaoXioe/nix-custompkgs";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    custompkgs = {
      url = "path:/home/klein-moretti/nix-custompkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    custompkgs-priv = {
      url = "github:XiaoXioe/nix-custompkg-priv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

  };

  outputs =
    inputs@{ ... }:
    let
      lib = inputs.nixpkgs.lib;
      hostName = "KleinMoretti";
      flakePath = "/home/${adminUser}/nixos-config";
      system = "x86_64-linux";
      adminUser = "klein-moretti";

      # User data & custom library
      userData = import ./hosts/nixos/users.nix;
      selfLib = import ./lib { inherit lib; };

      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ ];
      };

      # Shared arguments for both NixOS and Home Manager
      baseArgs = {
        inherit
          inputs
          selfLib
          hostName
          flakePath
          userData
          ;
        userName = adminUser;
        fullName = userData.fullName;
        userFeatures = userData.userFeatures or { };
      };

      homeModules = [
        ./hosts/nixos/home.nix
      ];

      commonModules = [
        ./hosts/nixos
        ./modules
        inputs.preservation.nixosModules.preservation
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-flatpak.nixosModules.nix-flatpak
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = baseArgs;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.users.${adminUser} = {
            imports = homeModules;
          };
        }
      ];

      # Build configurations using extracted builders
      builders = import ./lib/builders.nix {
        inherit
          lib
          pkgs
          hostName
          baseArgs
          commonModules
          ;
      };

      inherit (builders)
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

      packages.${system} = import ./packages-export.nix {
        nixosConfigs = mkNixosConfigurations;
        inherit hostName adminUser inputs;
      };
    };
}
