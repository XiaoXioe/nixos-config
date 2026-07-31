{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "ai.kaggle";
  description = "Kaggle CLI & SDK setup";

  nixosConfig = {
    sops.secrets = builtins.listToAttrs [
      (selfLib.secrets.mkSecret {
        key = "kaggle-token";
        owner = config.my.user.name;
        mode = "0400";
      })
    ];
    sops.templates."access_token" = {
      path = "/home/${config.my.user.name}/.kaggle/access_token";
      owner = config.my.user.name;
      mode = "0600";
      content = ''
        ${config.sops.placeholder.kaggle-token}
      '';
    };
    systemd.tmpfiles.rules = [
      "d /home/${config.my.user.name}/.kaggle 0700 ${config.my.user.name} users - -"
    ];
  };

  hmConfig =
    hmOpts:
    let
      myPython = pkgs.python3.override {
        packageOverrides = self: super: {
          kagglesdk = super.kagglesdk.overrideAttrs (
            finalAttrs: oldAttrs: {
              version = "0.1.34";
              src = pkgs.fetchPypi {
                pname = "kagglesdk";
                inherit (finalAttrs) version;
                hash = "sha256-DAp6Gp20d77k+hlOQR6A/Y2TunOXfaQAF1Ui8c+S2lg=";
              };
            }
          );

          kaggle = super.kaggle.overrideAttrs (
            finalAttrs: oldAttrs: {
              version = "2.2.3";
              src = pkgs.fetchPypi {
                pname = "kaggle";
                inherit (finalAttrs) version;
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
            }
          );
        };
      };
      kaggle-app = myPython.pkgs.toPythonApplication myPython.pkgs.kaggle;
    in
    {
      home.packages = [
        kaggle-app
      ];
    };
}
