{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.security-wrappers;
in
{
  options.my.system.security-wrappers = {
    enable = selfLib.mkBoolOpt false "system security wrappers and capabilities";
  };

  config = lib.mkIf cfg.enable {
    security.wrappers.nethogs = {
      source = "${pkgs.nethogs}/bin/nethogs";
      capabilities = "cap_net_admin,cap_net_raw+ep";
      owner = "root";
      group = "root";
    };

    # Mengaktifkan modul Wireshark beserta pembungkus keamanannya (capabilities)
    programs.wireshark = {
      enable = true;
      # Baris di bawah ini memaksa NixOS untuk menginstal versi GUI (Qt).
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
      source = "${pkgsUnstable.btop}/bin/btop";
      capabilities = "cap_sys_admin,cap_sys_rawio+ep";
    };
  };
}
