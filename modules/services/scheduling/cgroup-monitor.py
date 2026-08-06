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
