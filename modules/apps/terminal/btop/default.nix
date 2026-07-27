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

  hmConfig = hmOpts: {
    programs.btop = {
      enable = true;

      settings = {
        color_theme = "adwaita-dark.theme";
        theme_background = false;
        update_ms = 1000;
        proc_sorting = "cpu direct";
        mem_graphs = false;
        graph_symbol = "braille";
        disks_filter = "/ /mnt/data /mnt/data_btrfs";
        show_swap = true;
        swap_disk = false;
        rounded_corners = true;
        net_iface = "eth0";
      };
    };
  };

}
