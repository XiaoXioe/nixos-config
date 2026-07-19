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

    def get_cgroup_io(target_prefix=None):
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
                            parts = line.strip().split()
                            if parts:
                                # Jika target_prefix ditentukan, filter hanya cgroup dari disk tersebut
                                if target_prefix is None or parts[0] == target_prefix:
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
        if len(sys.argv) < 2:
            print("Error: Disk target tidak ditentukan. Gunakan: script.py <disk_device_path>", file=sys.stderr)
            sys.exit(1)
        target_disk = sys.argv[1]
        try:
            s = os.stat(target_disk)
            target_major = os.major(s.st_rdev)
            target_minor = os.minor(s.st_rdev)
            target_prefix = f"{target_major}:{target_minor}"
        except Exception as e:
            print(f"Warning: Gagal mengakses disk target {target_disk}: {e}", file=sys.stderr)
            target_prefix = None

        boot_id = get_boot_id()
        current = get_cgroup_io(target_prefix)
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
            
            # If cur_val < prev_val, the cgroup restarted and reset to 0
            if cur_val["r"] < prev_val["r"]:
                delta_r = cur_val["r"]
            else:
                delta_r = cur_val["r"] - prev_val["r"]

            if cur_val["w"] < prev_val["w"]:
                delta_w = cur_val["w"]
            else:
                delta_w = cur_val["w"] - prev_val["w"]

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

    my.hardware.preservation.extraDirectories = [
      "/var/lib/ssd-tracker"
    ];

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
}
