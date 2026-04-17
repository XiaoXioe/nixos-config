{
  lib,
  selfLib,
  userName,
  fullName,
  flakePath,
  ...
}:

{
  options.my.user = {
    name = selfLib.mkOpt lib.types.str userName "The main user account name";
    fullName = selfLib.mkOpt lib.types.str fullName "The full name of the user";
    flakePath = selfLib.mkOpt lib.types.str flakePath "The path to the nixos configuration flake";
  };
}
