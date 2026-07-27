{
  config,
  selfLib,
  ...
}:
let
  adminUsers = [ config.my.user.name ];
  nopassCmds = config.my.security.auth.nopassCmds;
in
selfLib.mkModule {
  name = "security.auth.doas";
  description = "OpenBSD doas privilege escalation";

  nixosConfig = {
    security.doas = {
      enable = true;
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
  };
}
