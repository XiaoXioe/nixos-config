# System-wide options metadata: host identity and user info.
{
  config,
  lib,
  ...
}:
{
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.nonEmptyStr;
    };
    fullName = lib.mkOption {
      type = lib.types.nonEmptyStr;
    };
    flakePath = lib.mkOption {
      type = lib.types.nonEmptyStr;
    };
  };

  options.my.hostname = lib.mkOption {
    type = lib.types.nonEmptyStr;
  };

  config = {
    networking.hostName = config.my.hostname;
  };
}
