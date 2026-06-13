{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.scheduling.ssd-monitor";

  nixosConfig = {
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

        # Auto-detect SSD
        TARGET_DISK=$(lsblk -d -n -o NAME,TYPE,ROTA | awk '$2=="disk" && $3=="0" && $1 !~ /^zram/ {print "/dev/"$1}' | head -n 1)

        if [ -z "$TARGET_DISK" ]; then
            echo "Error: SSD tidak ditemukan."
            exit 1
        fi

        # Menarik raw data Write dan Read
        RAW_W=$(smartctl -A "$TARGET_DISK" | grep -i "Total_LBAs_Written" | awk '{print $NF}')
        RAW_R=$(smartctl -A "$TARGET_DISK" | grep -i "Total_LBAs_Read" | awk '{print $NF}')

        if ! [[ "$RAW_W" =~ ^[0-9]+$ ]] || ! [[ "$RAW_R" =~ ^[0-9]+$ ]]; then
            echo "Error: Gagal mengambil data smartctl dari $TARGET_DISK. Pastikan SSD mendukung atribut tersebut."
            exit 1
        fi

        # Konversi ke GB
        GB_W=$(printf "%.2f" $(echo "scale=2; ($RAW_W * 32) / 1024" | bc))
        GB_R=$(printf "%.2f" $(echo "scale=2; ($RAW_R * 32) / 1024" | bc))

        if [ -s "$LOG_FILE" ]; then
            # Ambil baris terakhir
            LAST_LINE=$(tail -n 1 "$LOG_FILE")

            # Posisi $5 adalah angka Total Written (dari format lama dan baru)
            # Posisi $14 adalah angka Total Read (hanya ada di format baru)
            LAST_GB_W=$(echo "$LAST_LINE" | awk '{print $5}')
            LAST_GB_R=$(echo "$LAST_LINE" | awk '{print $14}')

            # Kalkulasi selisih Penulisan (Write)
            if [[ "$LAST_GB_W" =~ ^[0-9.]+$ ]]; then
                DIFF_W=$(echo "scale=2; $GB_W - $LAST_GB_W" | bc)
            else
                DIFF_W="0.00"
            fi

            # Kalkulasi selisih Pembacaan (Read)
            if [[ "$LAST_GB_R" =~ ^[0-9.]+$ ]]; then
                DIFF_R=$(echo "scale=2; $GB_R - $LAST_GB_R" | bc)
            else
                DIFF_R="0.00"
            fi

            echo "$DATE | Write: $GB_W GB | Penulisan Baru: $DIFF_W GB | Read: $GB_R GB | Baca Baru: $DIFF_R GB" >> "$LOG_FILE"
        else
            echo "$DATE | Write: $GB_W GB | Penulisan Baru: 0.00 GB | Read: $GB_R GB | Baca Baru: 0.00 GB" >> "$LOG_FILE"
        fi

        echo "--- Riwayat Penggunaan SSD ($TARGET_DISK) ---"
        tail -n 5 "$LOG_FILE"
      '';
    };
  };
}
