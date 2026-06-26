{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "scripts.file-transfer";
  description = "File transfer scripts (ambil & kirim)";

  hmConfig = hmOpts: {
    home.packages = [
      (pkgs.writers.writePython3Bin "ambil" { flakeIgnore = [ "E501" ]; } ''
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
      '')

      (pkgs.writers.writePython3Bin "kirim" { flakeIgnore = [ "E501" ]; } ''
        import os
        import shutil
        import subprocess
        import sys
        import tempfile


        # Kode warna untuk terminal
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


        # Fungsi untuk menjalankan rsync dengan tampilan bersih
        def run_rsync_clean(source, dest, description):
            print(f"{description}...", end=" ", flush=True)

            # Flag rahasia agar log bersih:
            # -a : Archive mode (copy semua atribut)
            # -h : Human readable numbers
            # --info=progress2 : Tampilkan Total Progress Bar (bukan list file)
            # --no-inc-recursive : Supaya estimasi waktu akurat sejak awal
            cmd = [
                "rsync",
                "-ah",
                "--partial",
                # "--append-verify",
                "--info=progress2",
                "--partial-dir=.rsync-partial",
                "--no-inc-recursive",
                source,
                dest,
            ]
            try:
                # Jalankan proses, tangkap error jika ada
                result = subprocess.run(cmd, stderr=subprocess.PIPE, text=True)

                if result.returncode == 0:
                    # Jika sukses, beri centang hijau dan baris baru
                    print(f"\r{description}... {Colors.GREEN}✔ Selesai{Colors.ENDC}          ")
                    return True
                else:
                    # Jika gagal, tampilkan error aslinya
                    print(f"\r{description}... {Colors.FAIL}✘ GAGAL{Colors.ENDC}")
                    print(f"{Colors.FAIL}--- Detail Error ---{Colors.ENDC}")
                    print(result.stderr.strip())
                    return False

            except Exception as e:
                print(f"\n{Colors.FAIL}System Error: {e}{Colors.ENDC}")
                return False


        def perform_transfer(source, destination):
            source_is_remote = ":" in source
            dest_is_remote = ":" in destination

            # --- SKENARIO 1: Remote ke Remote (Transit di PC) ---
            if source_is_remote and dest_is_remote:
                print_status(
                    f"Mode Transit: {source.split(':')[0]} -> PC -> {destination.split(':')[0]}"
                )

                if not shutil.which("rsync"):
                    print_status("Rsync tidak ditemukan!", "error")
                    return

                # Context Manager ini MENJAMIN folder dihapus otomatis setelah blok kode selesai
                with tempfile.TemporaryDirectory() as tmpdirname:
                    # Tentukan nama file/folder asli
                    src_path_only = source.split(":", 1)[1].rstrip("/")
                    filename = os.path.basename(src_path_only)
                    if not filename:
                        filename = "data_transit"

                    # Path transit di PC (Folder Temp)
                    local_transit_path = os.path.join(tmpdirname, filename)

                    # Step A: Tarik ke PC
                    # Kita download ke folder tmpdirname (jangan lupa trailing slash agar masuk ke dalam)
                    success = run_rsync_clean(
                        source.rstrip("/"), tmpdirname + "/", "1/2 Menarik data ke PC"
                    )
                    if not success:
                        return

                    # Step B: Dorong ke Tujuan
                    success = run_rsync_clean(
                        local_transit_path, destination, "2/2 Mengirim ke HP Tujuan"
                    )
                    if not success:
                        return

                # Begitu keluar dari blok 'with', folder tmpdirname otomatis musnah
                return

            # --- SKENARIO 2: Upload (Lokal ke Remote) ---
            if not source_is_remote:
                if not os.path.exists(source):
                    print_status(f"File tidak ditemukan: {source}", "error")
                    return

                if shutil.which("rsync"):
                    run_rsync_clean(source, destination, "Mengupload data")
                    return
                else:
                    # Fallback ke SCP jika rsync tidak ada (jarang terjadi di Arch)
                    print_status("Fallback SCP...", "warn")
                    subprocess.run(["scp", "-r", source, destination])

            # --- SKENARIO 3: Download (Remote ke Lokal) ---
            # (Jaga-jaga jika user pakai script ini untuk download juga)
            if source_is_remote and not dest_is_remote:
                run_rsync_clean(source, destination, "Mendownload data")


        def main():
            args = sys.argv[1:]
            clean_args = [arg for arg in args if arg.lower() not in ["ke", "to"]]

            if len(clean_args) < 2:
                print_status("Format salah!", "error")
                print("Contoh: kirim mido:file1,file2 ke nikel:")
                sys.exit(1)

            raw_source = clean_args[0]
            destination = clean_args[1]

            # Logic Parsing Koma (Bulk Send)
            sources_to_process = []
            if ":" in raw_source:
                host_part, path_part = raw_source.split(":", 1)
                if "," in path_part:
                    files = path_part.split(",")
                    for f in files:
                        f = f.strip()
                        if f:
                            sources_to_process.append(f"{host_part}:{f}")
                else:
                    sources_to_process.append(raw_source)
            else:
                if "," in raw_source:
                    files = raw_source.split(",")
                    for f in files:
                        f = f.strip()
                        if f:
                            sources_to_process.append(f)
                else:
                    sources_to_process.append(raw_source)

            # Eksekusi Loop
            print(
                f"{Colors.HEADER}--- Mulai Transfer ({len(sources_to_process)} Item) ---{Colors.ENDC}"
            )
            for src in sources_to_process:
                perform_transfer(src, destination)


        if __name__ == "__main__":
            main()
      '')
    ];

    # Integrasi autocompletion langsung ke konfigurasi Fish di Home Manager
    xdg.configFile."fish/completions/ambil.fish".text = ''
      complete -c ambil -a "(grep '^Host ' ~/.ssh/config_raw | awk '{print \$2}')"
    '';

    xdg.configFile."fish/completions/kirim.fish".text = ''
      complete -c kirim -a "(grep '^Host ' ~/.ssh/config_raw | awk '{print \$2}')"
    '';
  };
}
