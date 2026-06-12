{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.security.wrappers;
in
{
  options = selfLib.mkNestedEnable "security.wrappers";

  config = lib.mkIf cfg.enable {
    security.wrappers.nethogs = {
      source = "${pkgs.nethogs}/bin/nethogs";
      capabilities = "cap_net_admin,cap_net_raw+ep";
      owner = "root";
      group = "root";
    };

    # Enable Wireshark with security wrappers (capabilities)
    programs.wireshark = {
      enable = true;
      # Force install the Qt GUI version.
      package = pkgs.wireshark;
    };

    services.tor = {
      enable = true;
      client.enable = true;
    };
    systemd.services.tor.wantedBy = lib.mkForce [ ];

    security.wrappers.btop = {
      owner = "root";
      group = "root";
      source = "${pkgs.btop}/bin/btop";
      capabilities = "cap_sys_admin,cap_sys_rawio+ep";
    };
  };
}
