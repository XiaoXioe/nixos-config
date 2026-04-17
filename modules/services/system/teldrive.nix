{
  config,
  lib,
  pkgs,
  selfLib,
  inputs,
  ...
}:

let
  cfg = config.my.services.teldrive;
in
{
  options.my.services.teldrive = {
    enable = selfLib.mkBoolOpt false "Teldrive service";
  };
  config = lib.mkIf cfg.enable {

    # 1. Konfigurasi PostgreSQL
    services.postgresql = {
      enable = true;

      # Memasukkan ekstensi pgroonga ke dalam instalasi PostgreSQL
      extensions = with pkgs.postgresqlPackages; [ pgroonga ];

      ensureDatabases = [ "teldrive" ];
      ensureUsers = [
        {
          name = "teldrive";
          ensureDBOwnership = true;
          ensureClauses = {
            login = true;
            superuser = true;
          };
        }
      ];
    };

    # 2. Konfigurasi Agenix
    # konfig disimpan di ../system/security/secrets.nix

    # 3. Membuat User & Group khusus untuk isolasi keamanan
    users.users.teldrive = {
      isSystemUser = true;
      group = "teldrive";
      description = "User for Teldrive service";
    };
    users.groups.teldrive = { };

    # 4. Systemd Service untuk Teldrive
    systemd.services.teldrive = {
      description = "Teldrive - Telegram as Cloud Storage";
      # Pastikan berjalan setelah network dan database siap
      after = [
        "sops-nix.service"
        "network.target"
        "postgresql.service"
      ];
      wants = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "teldrive";
        Group = "teldrive";

        # Jalankan teldrive dengan flag --config mengarah ke path rahasia agenix
        ExecStart = "${
          inputs.custompkgs.packages.${pkgs.stdenv.hostPlatform.system}.teldrive
        }/bin/teldrive run --config ${config.sops.secrets.teldrive_config.path} --server-port 9090";

        Restart = "on-failure";
        RestartSec = "10s";

        # --- Hardening Security (Opsional tapi sangat disarankan) ---
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        # Memberikan direktori state di /var/lib/teldrive untuk cache/session jika diperlukan
        StateDirectory = "teldrive";
        WorkingDirectory = "/var/lib/teldrive";
      };
    };
  };
}
