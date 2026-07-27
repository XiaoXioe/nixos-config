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
  };

  imports = selfLib.scanPaths ./.;
}
