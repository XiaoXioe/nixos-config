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
  name = "security.auth.sudo";
  description = "Standard sudo privilege escalation";

  nixosConfig = {
    security.sudo = {
      enable = lib.mkForce true;
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
