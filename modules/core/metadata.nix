# System-wide options metadata: host identity and user info.
{
  config,
  lib,
  ...
}:
{
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  options.my.hostname = lib.mkOption {
    type = lib.types.str;
    default = "";
  };

  config = {
    networking.hostName = config.my.hostname;
  };
}
