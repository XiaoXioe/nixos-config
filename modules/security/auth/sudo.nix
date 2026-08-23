{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.auth.sudo";
  description = "Standard sudo privilege escalation";

  nixosConfig = {
    security.sudo = {
      enable = lib.mkForce true;
      extraRules = config.my.security.auth._sudoNopassRules;
    };
  };
}
