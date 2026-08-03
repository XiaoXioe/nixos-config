{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "services.storage.btrfs-nocow-migration";

  options = {
    nocowDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of directory paths to automatically migrate to Btrfs Copy-on-Write disabled (nocow, +C).
        Can be relative to the user's home directory or absolute paths outside home.
      '';
    };
  };

  nixosConfig =
    let
      cfg = config.my.services.storage.btrfs-nocow-migration;
    in
    {
      my.services.storage.btrfs-nocow-migration.nocowDirectories = [
        "/var/lib/vnstat"
        "/nix/var/nix/db"
      ];

      systemd.tmpfiles.rules = [
        "h /nix/var/nix/db - - - - +C"
        "h /nix/var/nix/temproots - - - - +C"
      ]
      ++ (lib.concatLists (
        map (
          dir:
          let
            isAbsolute = lib.hasPrefix "/" dir;
            host_dir = if isAbsolute then dir else "/home/${config.my.user.name}/${dir}";
            persist_dir = "/persist${host_dir}";
          in
          if isAbsolute then
            [
              "h ${host_dir} - - - - +C"
            ]
          else
            [
              "d ${host_dir} 0700 ${config.my.user.name} users - +C"
              "d ${persist_dir} 0700 ${config.my.user.name} users - +C"
            ]
        ) cfg.nocowDirectories
      ));

      # Layanan otomatisasi migrasi direktori nocow pada saat boot (sebelum display manager aktif)
      systemd.services.btrfs-nocow-migration = lib.mkIf (cfg.nocowDirectories != [ ]) {
        description = "Automated Btrfs nocow directory migration";
        after = [ "local-fs.target" ];
        before = [ "display-manager.service" ];
        wantedBy = [ "multi-user.target" ];

        # JANGAN jalankan/restart layanan ini saat rebuild (nh os switch) agar terminal tidak menggantung
        restartIfChanged = false;
        stopIfChanged = false;

        path = with pkgs; [
          e2fsprogs
          coreutils
          gnugrep
          util-linux
          systemd
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          user_name="${config.my.user.name}"
          user_home="/home/$user_name"
          persist_home="/persist/home/$user_name"

          migrate_dir() {
            local input_path="$1"
            local host_dir
            local persist_dir

            # Tentukan host path dan persist path
            if [[ "$input_path" =~ ^/ ]]; then
              host_dir="$input_path"
              persist_dir="/persist$input_path"
            else
              host_dir="$user_home/$input_path"
              persist_dir="$persist_home/$input_path"
            fi

            # Tentukan target direktori migrasi (prioritaskan persisten jika ada bind-mount)
            local target_dir="$host_dir"
            local is_mount=false

            if [ -d "$persist_dir" ] && [ ! -L "$persist_dir" ]; then
              target_dir="$persist_dir"
              if findmnt -n "$host_dir" >/dev/null; then
                is_mount=true
              fi
            fi

            # Hanya proses jika direktori target ada dan bukan symlink
            if [ -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
              local has_c=false
              if lsattr -d "$target_dir" | grep -q 'C'; then
                has_c=true
              fi

              if [ "$has_c" = true ]; then
                if [ ! -f "$target_dir/.nocow-migrated" ]; then
                  echo "==> [nocow-migration] Atribut nocow (+C) sudah aktif pada $target_dir. Menandai migrasi selesai."
                  touch "$target_dir/.nocow-migrated"
                else
                  echo "==> [nocow-migration] $target_dir sudah memiliki atribut nocow dan marker migrasi."
                fi
              else
                echo "==> [nocow-migration] $target_dir belum memiliki atribut nocow (+C). Memulai migrasi..."

                # 1. Lepas semua mountpoint aktif yang berhubungan dengan host_dir atau target_dir
                local mounted_paths=()
                while read -r mnt src; do
                  if [[ "$src" == *"$target_dir"* ]] || [[ "$mnt" == "$host_dir"* ]]; then
                    mounted_paths+=("$mnt|$src")
                  fi
                done < <(findmnt -l -n -o TARGET,SOURCE 2>/dev/null || true)

                # Lepas mount dari mountpoint terdalam dahulu (order terbalik)
                for ((i=''${#mounted_paths[@]}-1; i>=0; i--)); do
                  local mnt_info="''${mounted_paths[i]}"
                  local mnt
                  mnt=$(echo "$mnt_info" | cut -d'|' -f1)
                  echo "==> [nocow-migration] Melepas mount aktif di $mnt secara aman"
                  if ! umount "$mnt"; then
                    echo "==> [nocow-migration] WARNING: Gagal melepaskan mount $mnt secara aman (sedang digunakan). Membatalkan migrasi $target_dir"
                    return 0
                  fi
                done

                # 2. Amankan backup jika ada sisa backup dari proses yang terputus (mencegah data loss)
                local backup_dir="$target_dir.nocow-bak"
                if [ -e "$backup_dir" ]; then
                  echo "==> [nocow-migration] WARNING: Folder backup $backup_dir ditemukan dari proses sebelumnya yang terputus. Mengembalikan data..."
                  if [ -e "$target_dir" ]; then
                    rm -rf "$target_dir"
                  fi
                  mv "$backup_dir" "$target_dir"
                fi

                # Buat cadangan baru
                mv "$target_dir" "$backup_dir"

                # 3. Buat direktori kosong baru dengan owner & mode yang sama, lalu set +C
                mkdir -p "$target_dir"
                chown --reference="$backup_dir" "$target_dir"
                chmod --reference="$backup_dir" "$target_dir"
                chattr +C "$target_dir"

                # 4. Salin kembali semua file (otomatis mewarisi +C dan menjaga seluruh permission/owner/xattrs)
                echo "==> [nocow-migration] Menyalin berkas dari backup..."
                cp -aT "$backup_dir" "$target_dir"

                # 5. Buat berkas penanda migrasi selesai
                touch "$target_dir/.nocow-migrated"

                # 6. Bersihkan backup
                rm -rf "$backup_dir"

                # 7. Pasang kembali semua mountpoint yang dilepas sebelumnya
                for mnt_info in "''${mounted_paths[@]}"; do
                  local mnt
                  local src
                  mnt=$(echo "$mnt_info" | cut -d'|' -f1)
                  src=$(echo "$mnt_info" | cut -d'|' -f2)
                  echo "==> [nocow-migration] Memasang kembali mount di $mnt"

                  # Coba jalankan systemd mount unit terlebih dahulu agar opsi-opsi fstab/preservation terjaga
                  local unit_name
                  unit_name=$(systemd-escape --suffix=mount --path "$mnt")
                  if systemctl start "$unit_name" 2>/dev/null; then
                    echo "==> [nocow-migration] Sukses memulai systemd mount unit: $unit_name"
                  else
                    # Fallback ke mount --bind jika unit tidak ada atau gagal
                    echo "==> [nocow-migration] Fallback: Memasang mount --bind dari $src ke $mnt"
                    mount --bind "$src" "$mnt"
                  fi
                done

                echo "==> [nocow-migration] Migrasi $target_dir selesai."
              fi
            fi
          }

          ${lib.concatMapStringsSep "\n" (dir: "migrate_dir ${lib.escapeShellArg dir}") cfg.nocowDirectories}
        '';
      };
    };
}
