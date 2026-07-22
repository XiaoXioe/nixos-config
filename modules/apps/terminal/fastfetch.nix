{
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.fastfetch";
  description = "Fastfetch configuration";

  nixosConfig = {
    sops.secrets."fastfetch-logo" = {
      format = "binary";
      sopsFile = ../../../secrets/binary/fastfetch-logo.enc;
      owner = config.my.user.name;
      mode = "0444";
    };
  };

  hmConfig = hmOpts: {
    programs.fastfetch = {
      enable = true;

      settings = {
        logo = {
          source = hmOpts.osConfig.sops.secrets."fastfetch-logo".path;
          type = "kitty";
          height = 15;
          padding = {
            top = 1;
            right = 2;
          };
        };

        display = {
          size = {
            maxPrefix = "GB";
            ndigits = 2;
          };
          separator = "  ";
        };

        modules = [
          "title"
          "separator"
          {
            type = "os";
            key = "OS   ";
            keyColor = "blue";
          }
          {
            type = "host";
            key = "Host ";
            keyColor = "blue";
          }
          {
            type = "kernel";
            key = "Kern ";
            keyColor = "blue";
          }
          {
            type = "uptime";
            key = "Up   ";
            keyColor = "blue";
          }
          {
            type = "packages";
            key = "Pkgs ";
            keyColor = "blue";
          }
          "separator"
          {
            type = "wm";
            key = "WM   ";
            keyColor = "magenta";
          }
          {
            type = "shell";
            key = "Sh   ";
            keyColor = "magenta";
          }
          {
            type = "terminal";
            key = "Term ";
            keyColor = "magenta";
          }
          {
            type = "theme";
            key = "Thm  ";
            keyColor = "magenta";
          }
          "separator"
          {
            type = "cpu";
            key = "CPU  ";
            keyColor = "green";
          }
          {
            type = "gpu";
            key = "GPU  ";
            keyColor = "green";
          }
          {
            type = "memory";
            key = "Mem  ";
            keyColor = "green";
          }
          {
            type = "disk";
            key = "Disk ";
            keyColor = "green";
          }
          "break"
          "colors"
        ];
      };
    };
  };
}
