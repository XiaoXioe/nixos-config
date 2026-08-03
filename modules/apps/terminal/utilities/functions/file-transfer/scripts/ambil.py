import os
import shutil
import subprocess
import sys


# Warna untuk output
class Colors:
    HEADER = "\033[95m"
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"


def print_status(message, status="info"):
    if status == "info":
        print(f"{Colors.BLUE}[INFO]{Colors.ENDC} {message}")
    elif status == "success":
        print(f"{Colors.GREEN}[SUKSES]{Colors.ENDC} {message}")
    elif status == "warn":
        print(f"{Colors.WARNING}[WARN]{Colors.ENDC} {message}")
    elif status == "error":
        print(f"{Colors.FAIL}[ERROR]{Colors.ENDC} {message}")


def main():
    args = sys.argv[1:]

    # Hapus kata sambung 'dari', 'from', 'ke', 'to' agar perintah lebih natural
    clean_args = [
        arg for arg in args if arg.lower() not in ["dari", "from", "ke", "to"]
    ]

    if len(clean_args) < 1:
        print_status("Format salah!", "error")
        print("Usage: ambil <host:file_remote> [folder_lokal]")
        print("Contoh: ambil mido-userland:foto.jpg")
        sys.exit(1)

    source = clean_args[0]

    # Jika tujuan tidak ditulis, otomatis simpan ke folder saat ini (.)
    if len(clean_args) >= 2:
        destination = clean_args[1]
    else:
        destination = "."
        print_status("Tujuan tidak ditentukan, menyimpan ke folder saat ini...", "info")

    # Validasi format source (Harus ada 'host:' atau setidaknya ':')
    if ":" not in source:
        print_status(
            "Source sepertinya bukan file remote (tidak ada tanda ':').", "warn"
        )
        print("Pastikan formatnya: hostname:path/file")

    print(f"{Colors.HEADER}--- Memulai Download File ---{Colors.ENDC}")
    print(f"Sumber (Remote) : {source}")
    print(f"Tujuan (Lokal)  : {os.path.abspath(destination)}")

    # 1. Coba RSYNC
    if shutil.which("rsync"):
        # Parameter rsync untuk download sama saja: source -> dest
        rsync_cmd = [
            "rsync",
            "-avP",
            "--partial-dir=.rsync-partial",
            source,
            destination,
        ]
        try:
            print_status("Mencoba download dengan rsync...", "info")
            subprocess.run(rsync_cmd, check=True)
            print_status("Download selesai dengan rsync!", "success")
            return
        except subprocess.CalledProcessError:
            print_status("Gagal dengan rsync. Mencoba fallback ke SCP...", "warn")

    # 2. Fallback SCP
    scp_cmd = ["scp", "-r", source, destination]
    try:
        print_status("Mencoba download dengan scp...", "info")
        subprocess.run(scp_cmd, check=True)
        print_status("Download selesai dengan scp!", "success")
    except subprocess.CalledProcessError:
        print_status("Download GAGAL. Pastikan path remote benar.", "error")


if __name__ == "__main__":
    main()
