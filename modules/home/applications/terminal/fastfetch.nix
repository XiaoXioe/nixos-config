{
  config,
  lib,
  ...
}:

let
  cfg = config.my.user.fastfetch;
in
{
  options.my.user.fastfetch = {
    enable = lib.mkEnableOption "Fastfetch configuration";
  };

  config = lib.mkIf cfg.enable {

    programs.fastfetch = {
      enable = true;

      settings = {
        logo = {
          source = "/run/secrets/fastfetch-logo";
          type = "kitty";
          height = 15;
          padding = {
            top = 1;
            right = 2;
          };
        };

        display = {
          size = {
            maxPrefix = "GB"; # Mengubah satuan maksimal menjadi GB
            ndigits = 2; # Menampilkan 2 angka di belakang koma (contoh: 4.67 GB)
          };
          separator = "  ";
        };

        modules = [
          "title"
          "separator"

          # --- Informasi Sistem ---
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

          # --- Informasi Desktop & Tema ---
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

          # --- Informasi Hardware ---
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
