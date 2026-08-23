{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.auth.sudo-rs";
  description = "Memory-safe sudo-rs privilege escalation";

  nixosConfig = {
    security.sudo-rs = {
      enable = lib.mkForce true;
      execWheelOnly = true;
      extraRules = config.my.security.auth._sudoNopassRules;
    };
  };
}
