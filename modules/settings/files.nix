{
  config,
  pkgs,
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

    sops.secrets."foto-profile" = {
      format = "binary";
      owner = config.my.user.name;
      sopsFile = ../../secrets/binary/foto-profile.enc;
    };
  };

  hmConfig = hmOpts: {
    home.activation.setupFlatpakSymlinks = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Pastikan direktori penampung di home ada
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.var"
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.local/share"

      # Buat symlink langsung (ln -sfn) dari home ke target host
      # Hapus folder target asli jika ada untuk mencegah nested symlink
      if [ -d "$HOME/.var/app" ] && [ ! -L "$HOME/.var/app" ]; then
        ${pkgs.coreutils}/bin/rm -rf "$HOME/.var/app"
      fi
      if [ -d "$HOME/.local/share/flatpak" ] && [ ! -L "$HOME/.local/share/flatpak" ]; then
        ${pkgs.coreutils}/bin/rm -rf "$HOME/.local/share/flatpak"
      fi
      if [ -d "$HOME/.local/share/containers" ] && [ ! -L "$HOME/.local/share/containers" ]; then
        ${pkgs.coreutils}/bin/rm -rf "$HOME/.local/share/containers"
      fi

      ${pkgs.coreutils}/bin/ln -sfn /mnt/data_btrfs/flatpak-userdata "$HOME/.var/app"
      ${pkgs.coreutils}/bin/ln -sfn /mnt/data_btrfs/flatpak-local "$HOME/.local/share/flatpak"
      ${pkgs.coreutils}/bin/ln -sfn /mnt/data_btrfs/containers "$HOME/.local/share/containers"
    '';

    home.file."Documents".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Documents";
    home.file."Downloads".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Downloads";
    home.file."Pictures".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Pictures";
    home.file."Videos".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Videos";
    home.file."Music".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Music";

    home.file = {
      ".face.icon".source =
        hmOpts.config.lib.file.mkOutOfStoreSymlink
          hmOpts.osConfig.sops.secrets."foto-profile".path;
      ".face".source =
        hmOpts.config.lib.file.mkOutOfStoreSymlink
          hmOpts.osConfig.sops.secrets."foto-profile".path;
    };
  };
}
