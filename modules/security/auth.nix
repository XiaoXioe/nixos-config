{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.auth";
  description = "Authentication mechanisms (doas, sudo-rs)";

  options = {
    doas.enable = lib.mkEnableOption "doas privilege escalation";
    sudo.enable = lib.mkEnableOption "standard sudo privilege escalation";
    sudo-rs.enable = lib.mkEnableOption "sudo-rs memory-safe privilege escalation";
  };

  nixosConfig =
    let
      cfg = config.my.security.auth;
      adminUsers = [ config.my.user.name ];
      nopassCmds = [
        "nix-collect-garbage"
        "compsize"
        "dmesg"
        "ncdu"
      ];
    in
    {
      assertions = [
        {
          assertion = !(cfg.sudo.enable && cfg.sudo-rs.enable);
          message = "security.auth: Cannot enable both sudo and sudo-rs simultaneously. Choose one.";
        }
      ];

      security = {
        sudo = {
          enable = lib.mkForce cfg.sudo.enable;
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

        doas = {
          enable = cfg.doas.enable;
          extraRules = [
            {
              users = adminUsers;
              keepEnv = true;
              persist = true;
            }
          ]
          ++ (map (cmd: {
            users = adminUsers;
            noPass = true;
            keepEnv = true;
            cmd = cmd;
          }) nopassCmds);
        };

        sudo-rs = {
          enable = lib.mkForce cfg.sudo-rs.enable;
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

        rtkit = {
          enable = true;
        };
      };
    };
}
