{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.networking.zapret";
  description = "Zapret DPI bypass service (Manually activated)";

  nixosConfig = {
    services.zapret = {
      enable = true;
      params = [
        "--dpi-desync=split2"
      ];
      # Must be false for nftables firewalls as the module only auto-configures iptables.
      configureFirewall = false;
    };

    # Disable auto-start on boot by clearing the wantedBy target.
    # User can start/stop manually using: sudo systemctl start zapret
    systemd.services.zapret = {
      wantedBy = lib.mkForce [ ];
    };
  };
}
