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

  options.my.dataPath = lib.mkOption {
    type = lib.types.nonEmptyStr;
    default = "/mnt/data";
    description = "Global path for NTFS storage mount";
  };

  options.my.dataBtrfsPath = lib.mkOption {
    type = lib.types.nonEmptyStr;
    default = "/mnt/data_btrfs";
    description = "Global path for BTRFS storage mount";
  };

  options.my.defaultApps = {
    terminal = lib.mkOption {
      type = lib.types.str;
      default = "foot";
      description = "Default terminal emulator binary";
    };
    browser = lib.mkOption {
      type = lib.types.str;
      default = "zen-beta";
      description = "Default web browser binary";
    };
    editor = lib.mkOption {
      type = lib.types.str;
      default = "codium";
      description = "Default code/text editor binary";
    };
    fileManager = lib.mkOption {
      type = lib.types.str;
      default = "dolphin";
      description = "Default file manager binary";
    };
  };

  options.my.defaultTerminal = lib.mkOption {
    type = lib.types.str;
    default = config.my.defaultApps.terminal;
    description = "Alias to my.defaultApps.terminal";
  };

  config = {
    networking.hostName = config.my.hostname;
    home-manager.users.${config.my.user.name}.home.sessionVariables = {
      TERMINAL = config.my.defaultApps.terminal;
      BROWSER = config.my.defaultApps.browser;
      EDITOR = "${config.my.defaultApps.editor} -w";
      VISUAL = config.my.defaultApps.editor;
    };
  };
}
