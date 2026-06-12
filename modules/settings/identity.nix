# Per-user identity option declarations for home-manager.
{
  lib,
  userName,
  fullName,
  flakePath,
  ...
}:

{
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = userName;
      description = "The main user account name.";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = fullName;
      description = "The full display name of the user.";
    };
    flakePath = lib.mkOption {
      type = lib.types.str;
      default = flakePath;
      description = "Absolute path to the NixOS configuration flake.";
    };
  };
}
