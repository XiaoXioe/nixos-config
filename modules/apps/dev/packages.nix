{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.packages";
  description = "Packages for development";

  nixosConfig = {
    systemd.tmpfiles.rules = [
      "d /home/${config.my.user.name}/.android 0700 ${config.my.user.name} users - -"
    ];
    sops.secrets = {
      "adbkey_${config.my.user.name}" = {
        key = "adbkey";
        owner = config.my.user.name;
        path = "/home/${config.my.user.name}/.android/adbkey";
        mode = "0400";
      };
      "adbkey_pub_${config.my.user.name}" = {
        key = "adbkey_pub";
        owner = config.my.user.name;
        path = "/home/${config.my.user.name}/.android/adbkey.pub";
        mode = "0444";
      };
    };
  };

  hmConfig =
    hmOpts:
    let
      myPython = pkgs.python3.override {
        packageOverrides = self: super: {
          kagglesdk = super.kagglesdk.overrideAttrs (oldAttrs: rec {
            version = "0.1.34";
            src = pkgs.fetchPypi {
              pname = "kagglesdk";
              inherit version;
              hash = "sha256-DAp6Gp20d77k+hlOQR6A/Y2TunOXfaQAF1Ui8c+S2lg=";
            };
          });

          kaggle = super.kaggle.overrideAttrs (oldAttrs: rec {
            version = "2.2.3";
            src = pkgs.fetchPypi {
              pname = "kaggle";
              inherit version;
              hash = "sha256-ziksRZoTlQVT2JTuc2jWRUvlMpG9dcLSetK+0UnN1sQ=";
            };
            propagatedBuildInputs = with self; [
              bleach
              kagglesdk
              python-slugify
              requests
              python-dateutil
              tqdm
              urllib3
              packaging
              protobuf
              jupytext
              python-dotenv
            ];
            nativeBuildInputs = [ self.hatchling ] ++ (oldAttrs.nativeBuildInputs or [ ]);
          });
        };
      };
      kaggle-app = myPython.pkgs.toPythonApplication myPython.pkgs.kaggle;
    in
    {
      home.packages = with pkgs; [
        nodejs_22
        uv
        nix-tree
        nix-init
        python3
        cachix
        kaggle-app
      ];
    };
}
