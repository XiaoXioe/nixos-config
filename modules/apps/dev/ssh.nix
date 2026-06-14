{
  flakePath,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.ssh";
  description = "Ssh configuration";

  hmConfig = { config, ... }: {
    home.file.".ssh/config_raw".source =
      config.lib.file.mkOutOfStoreSymlink "${flakePath}/dotfiles/ssh-config/config.conf";
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
