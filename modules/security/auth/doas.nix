{
  config,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.auth.doas";
  description = "OpenBSD doas privilege escalation";

  # doas has a different rule format than sudo (uses noPass/cmd instead of commands/options),
  # so it formats rules locally rather than using the shared _sudoNopassRules.
  nixosConfig = {
    security.doas = {
      enable = true;
      extraRules = [
        {
          users = [ config.my.user.name ];
          keepEnv = true;
          persist = true;
        }
      ]
      ++ (map (cmd: {
        users = [ config.my.user.name ];
        noPass = true;
        keepEnv = true;
        inherit cmd;
      }) config.my.security.auth.nopassCmds);
    };
  };
}
