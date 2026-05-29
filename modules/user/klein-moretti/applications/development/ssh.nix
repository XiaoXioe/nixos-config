{
  config,
  lib,
  flakePath,
  ...
}:

let
  cfg = config.my.user.ssh;
in
{
  options.my.user.ssh = {
    enable = lib.mkEnableOption "Ssh configuration";
  };

  config = lib.mkIf cfg.enable {
    home.file.".ssh/config_raw".source =
      config.lib.file.mkOutOfStoreSymlink "${flakePath}/modules/user/conf/ssh-config/config.conf";
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [ "~/.ssh/config_raw" ];
      settings = {
        "*" = {
          SendEnv = "LANG LC_*";
        };
        "github.com" = {
          Host = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = "yes";
        };
      };
    };
  };
}
