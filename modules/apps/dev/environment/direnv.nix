{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.environment.direnv";
  description = "Direnv shell extension for project environment variable management";

  hmConfig = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      stdlib = ''
        declare -A direnv_layout_dirs
        direnv_layout_dir() {
          echo "''${direnv_layout_dirs[$PWD]:=/run/user/$(id -u)/direnv/layouts/$(echo -n "$PWD" | sha1sum | cut -d ' ' -f 1)}"
        }
      '';
    };
  };
}
