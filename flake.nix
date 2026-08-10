{
  description = "Klein Moretti's NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-26.05";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    custompkgs = {
      url = "github:XiaoXioe/nix-custompkgs";
      # url = "path:/home/klein-moretti/nix-custompkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    custompkgs-priv = {
      url = "github:XiaoXioe/nix-custompkg-priv";
      # url = "path:/home/klein-moretti/nix-custompkg-priv";
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
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };

    nix-mcp = {
      url = "github:XiaoXioe/nix-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mcp-nixos = {
      url = "github:utensils/mcp-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    torlink = {
      url = "github:baairon/torlink";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-zellij-043 = {
      # Pin ke commit nixpkgs yang membawa zellij 0.43.1.
      # Versi 0.44.x (nixpkgs 26.05) menyebabkan CPU spike konstan — jangan update.
      url = "github:NixOS/nixpkgs/9199b0bc1b2c11f5335cb5637b3a5ea20a27408b";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
      hostName = "KleinMoretti";

      # User data & custom library
      userData = import ./modules/hosts/nixos/users;
      adminUser = userData.userName;
      flakePath = "/home/${adminUser}/nixos-config";
      system = "x86_64-linux";

      selfLib = import ./modules/_lib { inherit lib inputs; };

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
        inherit (userData) fullName;
        userFeatures = userData.userFeatures or { };
      };

      homeModules = [
        ./modules/hosts/nixos/home
        inputs.nix-index-database.homeModules.nix-index
      ];

      commonModules = [
        ./modules/hosts/nixos
        ./modules
        inputs.preservation.nixosModules.preservation
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-flatpak.nixosModules.nix-flatpak
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

      # Build configurations using extracted builders
      builders = import ./modules/_lib/builders {
        inherit
          lib
          pkgs
          baseArgs
          commonModules
          system
          ;
      };

      mkNixosConfigurations = {
        ${hostName} = builders.mkNixosConfiguration hostName;
      };

      # Pre-commit / CI quality gate. Objektif & aman: format (nixfmt), dead
      # code (deadnix), dan linting (statix). Lambda arg diabaikan karena pola
      # `hmConfig = hmOpts:` sengaja menyisakan argumen tak terpakai (cegah shadowing)
      preCommitCheck = inputs.git-hooks.lib.${system}.run {
        src = ./.;
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

    in
    {
      formatter.${system} = pkgs.nixfmt;

      checks.${system}.pre-commit = preCommitCheck;

      devShells.${system}.default = pkgs.mkShell {
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

      nixosConfigurations = mkNixosConfigurations;

      packages.${system} = import ./modules/_lib/packages-export.nix {
        nixosConfigs = mkNixosConfigurations;
        inherit
          hostName
          adminUser
          inputs
          selfLib
          ;
      };
    };
}
