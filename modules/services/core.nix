{
  lib,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.core";

  nixosConfig = {
    environment.systemPackages = [
      pkgs.cloudflare-warp
    ];

    services = {
      guix.enable = true;
      thermald.enable = true;
      udisks2.enable = true;
      vnstat.enable = true;
      fstrim.enable = true;

      btrfs.autoScrub = {
        enable = true;
        interval = "*-*-01 10:00";
      };

      journald.extraConfig = ''
        SystemMaxUse=250M
        SystemMaxFileSize=50M
        Storage=persistent
        SyncIntervalSec=5m
        MaxRetentionSec=7day
      '';

      udev.extraRules = ''
        ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      '';

      cloudflare-warp.enable = true;

    };

    services.flatpak = {
      enable = true;
      uninstallUnmanaged = true;
      update = {
        onActivation = false;
        auto = {
          enable = true;
          onCalendar = "daily";
        };
      };
      restartOnFailure = {
        enable = true;
        restartDelay = "60s";
        exponentialBackoff = {
          enable = true;
          steps = 10;
          maxDelay = "1h";
        };
      };
      remotes = lib.mkDefault [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];
    };

    systemd.coredump.enable = false;

    systemd.services.cloudflare-warp-setup = {
      description = "Automate Cloudflare WARP Proxy Setup";
      wantedBy = [ "multi-user.target" ];
      after = [ "cloudflare-warp.service" ];
      requires = [ "cloudflare-warp.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Beri waktu sejenak agar daemon warp-svc benar-benar siap (listen)
        sleep 5

        # Cek status saat ini
        STATUS=$(${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos status)

        # Jika belum terdaftar, jalankan rangkaian perintah proxy
        if echo "$STATUS" | grep -qi "Registration missing"; then
          echo "Registrasi WARP belum ditemukan. Memulai konfigurasi otomatis..."
          ${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos registration new
          ${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos mode proxy
          ${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos proxy port 40000
          ${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos connect
          echo "Konfigurasi WARP Proxy selesai!"
        else
          echo "WARP sudah terkonfigurasi. Melewati setup."
        fi
      '';
    };

    systemd.services.cloudflare-warp = {
      serviceConfig = {
        LogLevelMax = "err";
      };
    };
  };
}
