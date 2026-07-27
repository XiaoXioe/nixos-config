{
  config,
  lib,
  selfLib,
  ...
}:
let
  adminUsers = [ config.my.user.name ];
  nopassCmds = config.my.security.auth.nopassCmds;
in
selfLib.mkModule {
  name = "security.auth.sudo-rs";
  description = "Memory-safe sudo-rs privilege escalation";

  nixosConfig = {
    security.sudo-rs = {
      enable = lib.mkForce true;
      execWheelOnly = true;
      extraRules = [
        {
          users = adminUsers;
          commands = map (cmd: {
            command = "/run/current-system/sw/bin/${cmd}";
            options = [ "NOPASSWD" ];
          }) nopassCmds;
        }
      ];
    };
  };
}
