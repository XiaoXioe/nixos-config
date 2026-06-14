{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.btop";
  description = "Btop configuration";

  nixosConfig = {
    security.wrappers = {
      btop = {
        owner = "root";
        group = "root";
        source = "${pkgs.btop}/bin/btop";
        capabilities = "cap_sys_admin,cap_sys_rawio+ep";
      };
    };
  };

  hmConfig = {
    programs.btop = {
      enable = true;

      settings = {
        color_theme = "adwaita-dark.theme";
        theme_background = false;
        update_ms = 1000;
        rounded_corners = false;
        graph_symbol = "braille";
        disks_filter = "/ /mnt/data /mnt/data_btrfs";
        show_swap = true;
        swap_disk = false;
        net_iface = "eth0";
      };
    };
  };

}
