{
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "settings.files";
  description = "Home file settings";

  nixosConfig = {
    systemd.tmpfiles.rules = [
      "d /mnt/data_btrfs/flatpak-userdata 0755 ${config.my.user.name} users - -"
      "d /mnt/data_btrfs/flatpak-local 0755 ${config.my.user.name} users - -"
      "d /mnt/data_btrfs/containers 0755 ${config.my.user.name} users - -"
    ];
  };

  hmConfig = hmOpts: {
    home.activation.setupFlatpakSymlinks = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Pastikan direktori penampung di home ada
      mkdir -p "$HOME/.var"
      mkdir -p "$HOME/.local/share"

      # Buat symlink langsung (ln -sfn) dari home ke target host
      # Hapus folder target asli jika ada untuk mencegah nested symlink
      if [ -d "$HOME/.var/app" ] && [ ! -L "$HOME/.var/app" ]; then
        rm -rf "$HOME/.var/app"
      fi
      if [ -d "$HOME/.local/share/flatpak" ] && [ ! -L "$HOME/.local/share/flatpak" ]; then
        rm -rf "$HOME/.local/share/flatpak"
      fi
      if [ -d "$HOME/.local/share/containers" ] && [ ! -L "$HOME/.local/share/containers" ]; then
        rm -rf "$HOME/.local/share/containers"
      fi

      ln -sfn /mnt/data_btrfs/flatpak-userdata "$HOME/.var/app"
      ln -sfn /mnt/data_btrfs/flatpak-local "$HOME/.local/share/flatpak"
      ln -sfn /mnt/data_btrfs/containers "$HOME/.local/share/containers"
    '';

    home.file."Documents".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Documents";
    home.file."Downloads".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Downloads";
    home.file."Pictures".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Pictures";
    home.file."Videos".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Videos";
    home.file."Music".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Music";

    home.file = {
      ".face.icon".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/run/secrets/foto-profile";
      ".face".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/run/secrets/foto-profile";
    };
  };
}
