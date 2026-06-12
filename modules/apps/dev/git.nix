{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.git";
  description = "user git configuration";

  hmConfig = {
    home.packages = with pkgs; [
      diff-so-fancy
      git-crypt
      hub
      tig
    ];
    programs.gh = {
      enable = true;
      package = pkgs.gh;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
        editor = "codium -w";
      };
    };
    programs.git = {
      enable = true;
      package = pkgs.git;
      settings = {
        user = {
          name = config.my.user.fullName;
          email = "169626976+XiaoXioe@users.noreply.github.com";
        };
        safe.directory = [
          "${config.home.homeDirectory}/nixos-config"
          "${config.home.homeDirectory}/nix-custompkgs-priv"
        ];
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };
  };
}
