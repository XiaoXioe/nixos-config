{
  config,
  lib,
  selfLib,
  flakePath,
  ...
}:

let
  cfg = config.my.user.ssh;
in
{
  options.my.user.ssh = {
    enable = selfLib.mkBoolOpt false "Ssh configuration";
  };

  config = lib.mkIf cfg.enable {
    home.file.".ssh/config_raw".source =
      config.lib.file.mkOutOfStoreSymlink "${flakePath}/modules/user/conf/ssh-config/config.conf";
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [ "~/.ssh/config_raw" ];
      matchBlocks = {
        "*" = {
          extraOptions = {
            SendEnv = "LANG LC_*";
          };
        };

        "github.com" = {
          host = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
        };
      };
    };
  };
}
