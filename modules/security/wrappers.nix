{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "security.wrappers";

  nixosConfig = {
    security.wrappers.nethogs = {
      source = "${pkgs.nethogs}/bin/nethogs";
      capabilities = "cap_net_admin,cap_net_raw+ep";
      owner = "root";
      group = "root";
    };

    security.wrappers.btop = {
      owner = "root";
      group = "root";
      source = "${pkgs.btop}/bin/btop";
      capabilities = "cap_sys_admin,cap_sys_rawio+ep";
    };
  };
}
