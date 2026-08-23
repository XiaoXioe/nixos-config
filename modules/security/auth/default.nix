{ selfLib, lib, ... }:

selfLib.mkModule {
  name = "security.auth";
  description = "Authentication mechanisms and privilege escalation";

  options = {
    nopassCmds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "nix-collect-garbage"
        "compsize"
        "dmesg"
        "ncdu"
      ];
      description = "List of commands allowed to run without password for admin users";
    };

    # Internal: pre-computed sudo/sudo-rs NOPASSWD extraRules from nopassCmds.
    # Consumed by sudo.nix and sudo-rs.nix to eliminate duplicate mapping logic.
    _sudoNopassRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      internal = true;
      default = [ ];
      description = "Pre-computed sudo NOPASSWD rules. Do not set directly.";
    };
  };

  nixosConfig =
    { config, ... }:
    {
      my.security.auth._sudoNopassRules = [
        {
          users = [ config.my.user.name ];
          commands = map (cmd: {
            command = "/run/current-system/sw/bin/${cmd}";
            options = [ "NOPASSWD" ];
          }) config.my.security.auth.nopassCmds;
        }
      ];
    };

  imports = selfLib.scanPaths ./.;
}
