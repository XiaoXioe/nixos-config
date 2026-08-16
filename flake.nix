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

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
      hostName = "KleinMoretti";

      adminUser = "klein-moretti";
      system = "x86_64-linux";

      selfLib = import ./modules/_lib { inherit lib inputs; };

      # Build configurations using extracted builders
      builders = import ./modules/_lib/builders {
        inherit
          lib
          inputs
          selfLib
          system
          ;
      };

      mkNixosConfigurations = {
        KleinMoretti = builders.mkNixosConfiguration "KleinMoretti";
      };
    in
    {
      formatter.${system} = builders.pkgs.nixfmt;

      checks.${system}.pre-commit = builders.preCommitCheck;

      devShells.${system}.default = builders.mkDevShell;

      nixosConfigurations = mkNixosConfigurations;

      packages.${system} = import ./modules/_lib/packages-export.nix {
        nixosConfigs = mkNixosConfigurations;
        inherit
          hostName
          adminUser
          inputs
          ;
      };
    };
}
