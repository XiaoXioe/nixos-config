{
  config,
  lib,
  selfLib,
  ...
}:

let
  # ── Password Manager & 2FA Desktop Applications Registry ──
  apps = {
    bitwarden = {
      description = "Bitwarden desktop password manager";
      pkgKey = "bitwarden";
      persist = [ ".config/Bitwarden" ];
      default = false;
    };
    proton-pass = {
      description = "Proton Pass desktop password manager";
      pkgKey = "proton_pass";
      persist = [ ".config/Proton Pass" ];
      default = false;
    };
    ente-auth = {
      description = "Ente Auth 2FA desktop authenticator";
      pkgKey = "ente_auth";
      persist = [
        ".local/share/io.ente.auth"
        ".config/enteauth"
      ];
      default = true;
    };
  };

  cfg = config.my.security.password-manager;
  activeApps = lib.filterAttrs (name: _: cfg.${name}.enable or false) apps;
in
selfLib.mkModule {
  name = "security.password-manager";
  description = "Native Password & 2FA manager desktop applications (Bitwarden, Proton Pass, Ente Auth) with pure upstream binaries";

  options = lib.mapAttrs (_: app: {
    enable = lib.mkOption {
      inherit (app) default;
      type = lib.types.bool;
      description = "Whether to enable ${app.description}.";
    };
  }) apps;

  preservation = {
    userDirectories = lib.concatMap (app: app.persist) (builtins.attrValues activeApps);
  };

  hmConfig = {
    home.packages = map (app: selfLib.fetchCachePinned app.pkgKey) (builtins.attrValues activeApps);
  };
}
