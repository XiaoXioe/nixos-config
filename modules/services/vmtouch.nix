{
  pkgs,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.vmtouch";
  description = "vmtouch service to lock files/directories into RAM (mlock) on startup";

  options = {
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = "List of paths or packages to lock into RAM at startup.";
    };
  };

  nixosConfig =
    { config, ... }:
    let
      cfg = config.my.services.vmtouch;
    in
    lib.mkIf (cfg.paths != [ ]) {
      environment.systemPackages = [ pkgs.vmtouch ];

      # "LimitMEMLOCK"/"LimitNOFILE" pada unit systemd hanya bisa menaikkan
      # rlimit proses SAMPAI hard limit sesi login (PAM). Hard limit default
      # untuk "memlock" biasanya sangat kecil (puluhan KB), sehingga
      # "vmtouch -l" gagal dengan "Cannot allocate memory" begitu menyentuh
      # file yang cukup besar walau unit sudah minta "infinity". Entri di
      # bawah ini menaikkan hard limit sesi login user, agar systemd user
      # manager (dan unit vmtouch di bawahnya) punya headroom untuk benar-benar
      # mengunci datanya.
      #
      # PENTING: perubahan limit PAM ini baru berlaku setelah re-login
      # (logout/login ulang, atau reboot) -- tidak cukup hanya rebuild.
      security.pam.loginLimits = [
        {
          domain = config.my.user.name;
          type = "hard";
          item = "memlock";
          value = "unlimited";
        }
        {
          domain = config.my.user.name;
          type = "soft";
          item = "memlock";
          value = "unlimited";
        }
        {
          domain = config.my.user.name;
          type = "hard";
          item = "nofile";
          value = "1048576";
        }
        {
          domain = config.my.user.name;
          type = "soft";
          item = "nofile";
          value = "1048576";
        }
      ];

      # "-l" (mlock) menjamin halaman tetap di RAM selama proses hidup, tidak
      # seperti "-t" (touch) yang cuma menjamin halaman dibaca sekali dan bisa
      # tergusur kapan saja setelahnya. Karena "-l" memblokir selamanya
      # (bukan oneshot), unit ini disupervisi sebagai proses foreground biasa
      # oleh systemd (Type = "simple"), bukan "oneshot".
      #
      # Trigger dipasang ke "default.target" (tercapai sekali per login),
      # bukan "graphical-session.target" yang di setup Hyprland/Niri ini
      # ternyata bisa restart berkali-kali dalam satu sesi, yang sebelumnya
      # membuat crawl berat ini terpicu ulang berkali-kali dan membanjiri
      # disk I/O.
      systemd.user.services.vmtouch = {
        description = "Lock files into RAM using vmtouch";
        after = [ "default.target" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";

          LimitMEMLOCK = "infinity";
          LimitNOFILE = 1048576;

          # Prioritas rendah agar crawl awal (~2GB baca disk) tidak bersaing
          # dengan aplikasi foreground untuk CPU/disk I/O saat service start.
          Nice = 19;
          IOSchedulingClass = "idle";

          ExecStart = pkgs.writeShellScript "vmtouch-start" ''
            exec ${pkgs.vmtouch}/bin/vmtouch -l -f ${lib.escapeShellArgs cfg.paths} 2> >(${pkgs.gnugrep}/bin/grep -v "WARNING: unable to stat" >&2)
          '';
        };
      };
    };
}
