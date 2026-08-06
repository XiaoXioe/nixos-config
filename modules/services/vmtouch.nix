{
  pkgs,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.vmtouch";
  description = "vmtouch service to pre-cache files/directories into system page cache (RAM) on startup";

  options = {
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = "List of paths or packages to touch (load into page cache) at startup.";
    };
  };

  nixosConfig =
    { config, ... }:
    let
      cfg = config.my.services.vmtouch;
    in
    lib.mkIf (cfg.paths != [ ]) {
      environment.systemPackages = [ pkgs.vmtouch ];

      systemd.user.services.vmtouch = {
        description = "Pre-cache files into RAM using vmtouch";
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "vmtouch-start" ''
            ${pkgs.vmtouch}/bin/vmtouch -t -f ${lib.escapeShellArgs cfg.paths} 2> >(${pkgs.gnugrep}/bin/grep -v "WARNING: unable to stat" >&2)
          '';
        };
      };
    };
}
