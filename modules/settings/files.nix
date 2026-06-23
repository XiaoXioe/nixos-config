{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "settings.files";
  description = "Home file settings";

  hmConfig = { config, lib, ... }: {
    home.activation.setupFlatpakSymlinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Buat folder target di host jika belum ada
      mkdir -p /mnt/data_btrfs/flatpak-userdata
      mkdir -p /mnt/data_btrfs/flatpak-local
      mkdir -p /mnt/data_btrfs/containers

      # Pastikan direktori penampung di home ada
      mkdir -p "$HOME/.var"
      mkdir -p "$HOME/.local/share"

      # Buat symlink langsung (ln -sfn) dari home ke target host
      ln -sfn /mnt/data_btrfs/flatpak-userdata "$HOME/.var/app"
      ln -sfn /mnt/data_btrfs/flatpak-local "$HOME/.local/share/flatpak"
      ln -sfn /mnt/data_btrfs/containers "$HOME/.local/share/containers"
    '';

    home.file."Documents".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Documents";
    home.file."Downloads".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Downloads";
    home.file."Pictures".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Pictures";
    home.file."Videos".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Videos";
    home.file."Music".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Music";

    home.file = {
      ".face.icon".source = config.lib.file.mkOutOfStoreSymlink "/run/secrets/foto-profile";
      ".face".source = config.lib.file.mkOutOfStoreSymlink "/run/secrets/foto-profile";
    };
  };
}
