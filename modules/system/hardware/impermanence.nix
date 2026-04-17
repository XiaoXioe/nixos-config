{
  config,
  lib,
  pkgs,
  selfLib,
  allUsers,
  ...
}:
let
  cfg = config.my.system.impermanence;

  persistDirs = [
    "/var/lib/bluetooth"
    "/etc/ssh"
    "/var/lib/nixos"
    "/var/lib/systemd/coredump"
    "/var/lib/waydroid"
    "/etc/NetworkManager/system-connections"
    "/var/lib/containers"
    "/var/lib/docker"
    "/var/lib/flatpak"
    "/var/lib/libvirt"
    "/var/lib/NetworkManager"
    "/var/lib/sddm"
    # "/var/tmp"
    "/var/cache/nix" # Cache binary substituters
    "/root"
    "/var/lib/pipewire"
    "/var/lib/alsa"
    "/var/log"
    "/var/lib/systemd/timers"
    "/var/lib/AccountsService"
    "/var/lib/ollama"
    "/var/lib/open-webui"
    "/var/lib/fail2ban"
    "/var/lib/vnstat"
    "/var/lib/tor"
  ];

  persistFiles = [
    "/etc/machine-id"
    "/var/lib/systemd/random-seed"
  ];

  restoreScript = pkgs.writeShellScriptBin "restore-persist-data" ''
    set -euo pipefail
    echo "Memulai pemulihan data dari /persist ke root filesystem..."

    ${lib.concatMapStringsSep "\n" (dir: ''
      if ${pkgs.util-linux}/bin/mountpoint -q "${dir}"; then
        echo "Melepaskan bind mount aktif: ${dir}"
        ${pkgs.util-linux}/bin/umount "${dir}" || true
      fi

      if [ -d "/persist${dir}" ] && [ ! -d "${dir}" ]; then
        echo "Memulihkan direktori: ${dir}"
        mkdir -p "$(dirname "${dir}")"
        ${pkgs.coreutils}/bin/mv "/persist${dir}" "${dir}"
      elif [ -d "/persist${dir}" ] && [ -d "${dir}" ]; then
        echo "Menyatukan direktori (menggunakan reflink CoW): ${dir}"
        ${pkgs.coreutils}/bin/cp -a --reflink=auto "/persist${dir}/." "${dir}/"
      fi
    '') persistDirs}

    ${lib.concatMapStringsSep "\n" (file: ''
      if ${pkgs.util-linux}/bin/mountpoint -q "${file}"; then
        ${pkgs.util-linux}/bin/umount "${file}" || true
      elif [ -h "${file}" ]; then
        echo "Menghapus symlink lama: ${file}"
        rm -f "${file}"
      fi

      if [ -f "/persist${file}" ] && [ ! -f "${file}" ]; then
        echo "Memulihkan file: ${file}"
        mkdir -p "$(dirname "${file}")"
        ${pkgs.coreutils}/bin/mv "/persist${file}" "${file}"
      elif [ -f "/persist${file}" ] && [ -f "${file}" ]; then
        echo "Menimpa file (menggunakan reflink CoW): ${file}"
        ${pkgs.coreutils}/bin/cp -a --reflink=auto "/persist${file}" "${file}"
      fi
    '') persistFiles}

    echo "Membersihkan sisa-sisa isi /persist secara paksa..."
    ${pkgs.findutils}/bin/find /persist -mindepth 1 -delete

    echo "Pemulihan dan pembersihan selesai!"
  '';
in
{
  options.my.system.impermanence = {
    enable = selfLib.mkBoolOpt false "system impermanence with persistence";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.persistence."/persist" = {
        hideMounts = true;

        directories = persistDirs;
        files = persistFiles;

        users = selfLib.forAllUsers allUsers (
          userName: _: {
            directories = [
              ".config"
              ".local/share"
              ".local/state"
              ".cache"
              ".ssh"
              ".android"
              ".gnupg"
              ".mozilla"
              ".thunderbird"
              "Documents"
              "Downloads"
              "Music"
              "Pictures"
              "Videos"
              ".local/share/fish/fish_history"
            ];
            files = [
              ".bash_history"
              ".zsh_history"
            ];
          }
        );
      };

      system.activationScripts.clearPersistRestoredMarker = lib.stringAfter [ "users" "groups" ] ''
        rm -f /persist/.persist-restored
      '';
    })

    # Selalu menyediakan skrip manual yang bisa dijalankan kapan saja
    {
      environment.systemPackages = [
        restoreScript
        pkgs.rsync
      ];
    }

    # Jika impermanence dimatikan, pulihkan dan bersihkan /persist saat rebuild
    (lib.mkIf (!cfg.enable) {
      system.activationScripts.restorePersistData = lib.stringAfter [ "users" "groups" ] ''
        if [ ! -f /persist/.persist-restored ]; then
          ${restoreScript}/bin/restore-persist-data
          # Menambahkan marker sebagai tanda bahwa /persist sudah dipulihkan
          mkdir -p /persist
          touch /persist/.persist-restored
        fi
      '';
    })
  ];
}
