{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.security.password-manager;
  bitwardenEnabled = cfg.bitwarden.enable or false;
  protonPassEnabled = cfg.proton-pass.enable or false;
  enteAuthEnabled = cfg.ente-auth.enable or true;

  bitwardenPkg = selfLib.fetchCachePinned "bitwarden";
  protonPassPkg = selfLib.fetchCachePinned "proton_pass";
  enteAuthPkg = selfLib.fetchCachePinned "ente_auth";
in
selfLib.mkModule {
  name = "security.password-manager";
  description = "Native Password & 2FA manager desktop applications (Bitwarden, Proton Pass, Ente Auth) with pure upstream binaries";

  options = {
    bitwarden = {
      enable = lib.mkEnableOption "Bitwarden desktop password manager";
    };
    proton-pass = {
      enable = lib.mkEnableOption "Proton Pass desktop password manager";
    };
    ente-auth = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable Ente Auth 2FA desktop authenticator.";
      };
    };
  };

  preservation = {
    userDirectories =
      (lib.optionals bitwardenEnabled [
        ".config/Bitwarden"
      ])
      ++ (lib.optionals protonPassEnabled [
        ".config/Proton Pass"
      ])
      ++ (lib.optionals enteAuthEnabled [
        ".local/share/io.ente.auth"
        ".config/enteauth"
      ]);
  };

  hmConfig = {
    home.packages =
      (lib.optionals bitwardenEnabled [ bitwardenPkg ])
      ++ (lib.optionals protonPassEnabled [ protonPassPkg ])
      ++ (lib.optionals enteAuthEnabled [ enteAuthPkg ]);

    xdg.desktopEntries = lib.mkMerge [
      (lib.mkIf bitwardenEnabled {
        bitwarden = {
          name = "Bitwarden";
          genericName = "Password Manager";
          comment = "A secure and free password manager for all of your devices";
          exec = "bitwarden-desktop %U";
          icon = "bitwarden";
          terminal = false;
          categories = [
            "Utility"
            "Security"
          ];
          mimeType = [ "x-scheme-handler/bitwarden" ];
        };
      })

      (lib.mkIf protonPassEnabled {
        proton-pass = {
          name = "Proton Pass";
          genericName = "Password Manager";
          comment = "Proton Pass Desktop application";
          exec = "proton-pass %U";
          icon = "proton-pass";
          terminal = false;
          categories = [
            "Utility"
            "Security"
          ];
          mimeType = [ "x-scheme-handler/protonpass" ];
        };
      })

      (lib.mkIf enteAuthEnabled {
        ente-auth = {
          name = "Ente Auth";
          genericName = "2FA Authenticator";
          comment = "End-to-end encrypted 2FA app";
          exec = "enteauth %U";
          icon = "io.ente.auth";
          terminal = false;
          categories = [
            "Utility"
            "Security"
          ];
          mimeType = [ "x-scheme-handler/enteauth" ];
        };
      })
    ];
  };
}
