{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.services.ssd-tbw;
in
{
  options.my.services.ssd-tbw = {
    enable = selfLib.mkBoolOpt false "SSD TBW logger service";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.smartmontools ];

    systemd.timers."ssd-tracker" = {
      wantedBy = [ "timers.target" ];
      description = "Timer untuk Laporan SSD TBW";
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };

    systemd.services."ssd-tracker" = {
      description = "SSD TBW Tracker Service";

      path = with pkgs; [
        bash
        smartmontools
        gawk
        bc
        coreutils
        util-linux
      ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        #!/usr/bin/env bash

        LOG_FILE="/var/log/ssd_history.log"
        DATE=$(date '+%Y-%m-%d %H:%M')

        # Deteksi otomatis SSD
        TARGET_DISK=$(lsblk -d -n -o NAME,TYPE,ROTA | awk '$2=="disk" && $3=="0" && $1 !~ /^zram/ {print "/dev/"$1}' | head -n 1)

        if [ -z "$TARGET_DISK" ]; then
            echo "Error: SSD tidak ditemukan."
            exit 1
        fi

        RAW=$(smartctl -A "$TARGET_DISK" | grep "Total_LBAs_Written" | awk '{print $NF}')

        if ! [[ "$RAW" =~ ^[0-9]+$ ]]; then
            echo "Error: Gagal mengambil data smartctl dari $TARGET_DISK."
            exit 1
        fi

        GB=$(printf "%.2f" $(echo "scale=2; ($RAW * 32) / 1024" | bc))

        if [ -s "$LOG_FILE" ]; then
            LAST_GB=$(tail -n 1 "$LOG_FILE" | awk '{print $5}')

            if [[ "$LAST_GB" =~ ^[0-9.]+$ ]]; then
                DIFF=$(echo "scale=2; $GB - $LAST_GB" | bc)
                echo "$DATE | Total: $GB GB | Penulisan Baru: $DIFF GB" >> "$LOG_FILE"
            else
                echo "$DATE | Total: $GB GB | Penulisan Baru: 0.00 GB (Fixing)" >> "$LOG_FILE"
            fi
        else
            echo "$DATE | Total: $GB GB | Penulisan Baru: 0.00 GB" >> "$LOG_FILE"
        fi

        echo "--- Riwayat Penulisan SSD ($TARGET_DISK) ---"
        tail -n 5 "$LOG_FILE"
      '';
    };
  };
}
