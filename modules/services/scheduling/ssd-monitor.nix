{
  pkgs,
  selfLib,
  ...
}:

let
  # Script dipindahkan ke file Python terpisah untuk maintainability lebih baik
  cgroupMonitor = ./cgroup-monitor.py;
in

selfLib.mkModule {
  name = "services.scheduling.ssd-monitor";

  nixosConfig = {
    environment.systemPackages = [ pkgs.smartmontools ];

    my.hardware.preservation.extraDirectories = [
      "/var/lib/ssd-tracker"
    ];

    systemd = {
      services."user@" = {
        serviceConfig = {
          Delegate = "pids memory cpu io";
        };
      };

      user.extraConfig = ''
        DefaultIOAccounting=yes
      '';

      timers."ssd-tracker" = {
        wantedBy = [ "timers.target" ];
        description = "Timer untuk Laporan SSD TBW";
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      services."ssd-tracker" = {
        description = "SSD TBW Tracker Service";
        onFailure = [ "status-alert@ssd-tracker.service" ];

        path = with pkgs; [
          bash
          smartmontools
          gawk
          bc
          coreutils
          util-linux
          python3
        ];

        serviceConfig = {
          Type = "oneshot";
          User = "root";
          StateDirectory = "ssd-tracker";
        };

        script = ''
          set -euo pipefail

          LOG_FILE="/var/lib/ssd-tracker/ssd_history.log"
          DATE=$(date '+%Y-%m-%d %H:%M')

          # Auto-detect SSD
          TARGET_DISK=$(lsblk -d -n -o NAME,TYPE,ROTA | awk '$2=="disk" && $3=="0" && $1 !~ /^zram/ {print "/dev/"$1}' | head -n 1)

          if [ -z "$TARGET_DISK" ]; then
              echo "Error: SSD tidak ditemukan."
              exit 1
          fi

          # Check if drive is NVMe or SATA
          if smartctl -a "$TARGET_DISK" | grep -q "Data Units Written"; then
              # NVMe drive
              RAW_W=$(smartctl -a "$TARGET_DISK" | grep -i "Data Units Written" | awk '{print $4}' | tr -d ',')
              RAW_R=$(smartctl -a "$TARGET_DISK" | grep -i "Data Units Read" | awk '{print $4}' | tr -d ',')

              if ! [[ "$RAW_W" =~ ^[0-9]+$ ]] || ! [[ "$RAW_R" =~ ^[0-9]+$ ]]; then
                  echo "Error: Gagal mengambil data SMART NVMe dari $TARGET_DISK."
                  exit 1
              fi
              
              # NVMe reports Data Units Written in 1000s of 512-byte units (512,000 bytes).
              # GB (base 2 GiB) = RAW_W * 1000 * 512 / 1024^3 = RAW_W * 500000 / 1073741824
              GB_W=$(printf "%.2f" "$(echo "scale=4; $RAW_W * 500000 / 1073741824" | bc)")
              GB_R=$(printf "%.2f" "$(echo "scale=4; $RAW_R * 500000 / 1073741824" | bc)")
          else
              # SATA drive
              RAW_W=$(smartctl -A "$TARGET_DISK" | grep -i "Total_LBAs_Written" | awk '{print $NF}')
              RAW_R=$(smartctl -A "$TARGET_DISK" | grep -i "Total_LBAs_Read" | awk '{print $NF}')

              if ! [[ "$RAW_W" =~ ^[0-9]+$ ]] || ! [[ "$RAW_R" =~ ^[0-9]+$ ]]; then
                  echo "Error: Gagal mengambil data SMART SATA dari $TARGET_DISK."
                  exit 1
              fi

              # Keep user SATA calculation for MidasForce SSD (reports in 32MB blocks)
              # GB_W = RAW_W * 32 / 1024
              GB_W=$(printf "%.2f" "$(echo "scale=2; ($RAW_W * 32) / 1024" | bc)")
              GB_R=$(printf "%.2f" "$(echo "scale=2; ($RAW_R * 32) / 1024" | bc)")
          fi

          if [ -s "$LOG_FILE" ]; then
              # Ambil baris terakhir yang memuat statistik 'Write:' agar tidak bentrok dengan detail per aplikasi
              LAST_LINE=$(grep "Write:" "$LOG_FILE" | tail -n 1)

              LAST_GB_W=$(echo "$LAST_LINE" | awk '{print $5}')
              LAST_GB_R=$(echo "$LAST_LINE" | awk '{print $14}')

              # Kalkulasi selisih Penulisan (Write)
              if [[ "$LAST_GB_W" =~ ^[0-9.]+$ ]]; then
                  # Tangani kemungkinan disk diganti atau counter wrap-around
                  if (( $(echo "$GB_W < $LAST_GB_W" | bc -l) )); then
                      DIFF_W="$GB_W"
                  else
                      DIFF_W=$(echo "scale=2; $GB_W - $LAST_GB_W" | bc)
                  fi
              else
                  DIFF_W="0.00"
              fi

              # Kalkulasi selisih Pembacaan (Read)
              if [[ "$LAST_GB_R" =~ ^[0-9.]+$ ]]; then
                  if (( $(echo "$GB_R < $LAST_GB_R" | bc -l) )); then
                      DIFF_R="$GB_R"
                  else
                      DIFF_R=$(echo "scale=2; $GB_R - $LAST_GB_R" | bc)
                  fi
              else
                  DIFF_R="0.00"
              fi

              echo "$DATE | Write: $GB_W GB | Penulisan Baru: $DIFF_W GB | Read: $GB_R GB | Baca Baru: $DIFF_R GB" >> "$LOG_FILE"
          else
              echo "$DATE | Write: $GB_W GB | Penulisan Baru: 0.00 GB | Read: $GB_R GB | Baca Baru: 0.00 GB" >> "$LOG_FILE"
          fi

          # Jalankan cgroup monitor dan masukkan hasilnya ke file log utama
          echo "=== Detail Penggunaan Per Apps/Service ===" >> "$LOG_FILE"
          CG_OUT=$(${pkgs.python3}/bin/python3 ${cgroupMonitor} "$TARGET_DISK" 2>&1)
          echo "$CG_OUT" >> "$LOG_FILE"
          echo "----------------------------------------" >> "$LOG_FILE"

          echo "--- Riwayat Penggunaan SSD ($TARGET_DISK) ---"
          grep "Write:" "$LOG_FILE" | tail -n 5
          echo ""
          echo "=== Detail Penggunaan Per Apps/Service (1 Jam Terakhir) ==="
          echo "$CG_OUT"
        '';
      };
    };
  };
}
