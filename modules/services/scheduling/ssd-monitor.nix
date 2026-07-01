{
  pkgs,
  selfLib,
  ...
}:

let
  cgroupMonitor = pkgs.writeText "cgroup-monitor.py" ''
    import os
    import json
    import re
    import sys

    STATE_FILE = "/var/lib/ssd-tracker/cgroups.json"

    def get_boot_id():
        try:
            with open("/proc/sys/kernel/random/boot_id", "r") as f:
                return f.read().strip()
        except Exception:
            return ""

    def get_cgroup_io():
        cgroups = {}
        for root, dirs, files in os.walk("/sys/fs/cgroup"):
            if "io.stat" in files:
                path = os.path.relpath(root, "/sys/fs/cgroup")
                if path == "." or not path:
                    continue
                basename = os.path.basename(path)
                # Lewati parent slice dan manager yang hanya menjumlahkan data dari anak-anaknya
                if basename.endswith(".slice") or re.match(r"^user@\d+\.service$", basename) or basename in ("init.scope",):
                    continue
                io_file = os.path.join(root, "io.stat")
                rbytes = 0
                wbytes = 0
                try:
                    with open(io_file, "r") as f:
                        for line in f:
                            match = re.search(r"rbytes=(\d+)\s+wbytes=(\d+)", line)
                            if match:
                                rbytes += int(match.group(1))
                                wbytes += int(match.group(2))
                except Exception:
                    continue
                if rbytes > 0 or wbytes > 0:
                    cgroups[path] = {"r": rbytes, "w": wbytes}
        return cgroups

    def friendly_name(path):
        # Flatpak apps
        m = re.search(r"user@\d+\.service/app\.slice/app-flatpak-([^/]+)-\d+\.scope", path)
        if m:
            return f"flatpak:{m.group(1)}"
        
        # User scopes (e.g., app-niri-wezterm-3189.scope)
        m = re.search(r"user@\d+\.service/app\.slice/app-([^/]+)-\d+\.scope", path)
        if m:
            return f"user-app:{m.group(1)}"

        # User services
        m = re.search(r"user@\d+\.service/app\.slice/app-([^/]+)\.service", path)
        if m:
            return f"user-service:{m.group(1)}"
        
        # System services
        m = re.search(r"system\.slice/([^/]+)\.service", path)
        if m:
            return f"system-service:{m.group(1)}"
        
        # System slices
        m = re.search(r"system\.slice/([^/]+)\.slice", path)
        if m:
            return f"system-slice:{m.group(1)}"

        parts = path.split("/")
        return parts[-1] if parts else path

    def format_bytes(b):
        if b < 1024:
            return f"{b} B"
        elif b < 1024 * 1024:
            return f"{b / 1024:.2f} KB"
        elif b < 1024 * 1024 * 1024:
            return f"{b / (1024 * 1024):.2f} MB"
        else:
            return f"{b / (1024 * 1024 * 1024):.2f} GB"

    def main():
        boot_id = get_boot_id()
        current = get_cgroup_io()
        previous = {}
        if os.path.exists(STATE_FILE):
            try:
                with open(STATE_FILE, "r") as f:
                    state = json.load(f)
                    if state.get("boot_id") == boot_id:
                        previous = state.get("cgroups", {})
            except Exception:
                pass

        try:
            os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
            with open(STATE_FILE, "w") as f:
                json.dump({"boot_id": boot_id, "cgroups": current}, f)
        except Exception as e:
            print(f"Warning: Gagal menyimpan state: {e}", file=sys.stderr)

        if not previous:
            print("Inisialisasi pemantauan I/O cgroup. Menunggu laporan jam berikutnya.")
            return

        deltas = []
        for path, cur_val in current.items():
            prev_val = previous.get(path, {"r": 0, "w": 0})
            delta_r = max(0, cur_val["r"] - prev_val["r"])
            delta_w = max(0, cur_val["w"] - prev_val["w"])
            if delta_r > 0 or delta_w > 0:
                deltas.append({
                    "path": path,
                    "name": friendly_name(path),
                    "r": delta_r,
                    "w": delta_w
                })

        top_write = sorted(deltas, key=lambda x: x["w"], reverse=True)[:5]
        top_read = sorted(deltas, key=lambda x: x["r"], reverse=True)[:5]

        print("=== TOP 5 DISK WRITE (1 Jam Terakhir) ===")
        for idx, item in enumerate(top_write, 1):
            if item["w"] > 0:
                print(f"{idx}. {item['name']}: {format_bytes(item['w'])}")

        print("\n=== TOP 5 DISK READ (1 Jam Terakhir) ===")
        for idx, item in enumerate(top_read, 1):
            if item["r"] > 0:
                print(f"{idx}. {item['name']}: {format_bytes(item['r'])}")

    if __name__ == "__main__":
        main()
  '';
in

selfLib.mkModule {
  name = "services.scheduling.ssd-monitor";

  nixosConfig = {
    environment.systemPackages = [ pkgs.smartmontools ];

    systemd.services."user@" = {
      serviceConfig = {
        Delegate = "pids memory cpu io";
      };
    };

    systemd.user.extraConfig = ''
      DefaultIOAccounting=yes
    '';

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
      wantedBy = [ "multi-user.target" ];

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
            # Ambil baris terakhir yang memuat statistik 'Write:' agar tidak bentrok dengan detail per aplikasi
            LAST_LINE=$(grep "Write:" "$LOG_FILE" | tail -n 1)

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

        # Jalankan cgroup monitor dan masukkan hasilnya ke file log utama
        echo "=== Detail Penggunaan Per Apps/Service ===" >> "$LOG_FILE"
        ${pkgs.python3}/bin/python3 ${cgroupMonitor} >> "$LOG_FILE" 2>&1
        echo "----------------------------------------" >> "$LOG_FILE"

        echo "--- Riwayat Penggunaan SSD ($TARGET_DISK) ---"
        tail -n 25 "$LOG_FILE"
      '';
    };
  };
}

