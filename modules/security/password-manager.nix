{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.security.password-manager;
  bitwardenEnabled = cfg.bitwarden.enable or false;
  protonPassEnabled = cfg.proton-pass.enable or false;
  enteAuthEnabled = cfg.ente-auth.enable or true;

  bitwardenInfo = selfLib.appVersions.bitwarden;
  protonPassInfo = selfLib.appVersions.proton-pass;
  enteAuthInfo = selfLib.appVersions.ente-auth;

  bitwardenNative = (selfLib.mkNativeApp pkgs) {
    name = "bitwarden";
    inherit (bitwardenInfo) version;
    src = selfLib.fetchApp pkgs "bitwarden";
    execPath = "opt/Bitwarden/bitwarden";
    binName = "bitwarden-desktop";
    extraArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
    ];
    extraEnv = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };

  protonPassNative = (selfLib.mkNativeApp pkgs) {
    name = "proton-pass";
    inherit (protonPassInfo) version;
    src = selfLib.fetchApp pkgs "proton-pass";
    execPath = "usr/lib/proton-pass/proton-pass";
    binName = "proton-pass";
    extraArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
    ];
    extraEnv = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };

  enteAuthNative = (selfLib.mkNativeApp pkgs) {
    name = "ente-auth";
    inherit (enteAuthInfo) version;
    src = selfLib.fetchApp pkgs "ente-auth";
    execPath = "usr/share/enteauth/enteauth";
    binName = "enteauth";
    extraArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
    ];
    extraEnv = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };
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
      (lib.optionals bitwardenEnabled [ bitwardenNative ])
      ++ (lib.optionals protonPassEnabled [ protonPassNative ])
      ++ (lib.optionals enteAuthEnabled [ enteAuthNative ]);

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
