{ pkgs }:

{
  "com.vscodium.codium" = {
    enable = true;
    overrides = {
      Context = {
        sockets = [
          "wayland"
          "x11"
          "fallback-x11"
          "session-bus"
        ];
        talk-name = [ "org.freedesktop.secrets" ];
        filesystems = [
          "host"
          "/tmp"
          "xdg-run/gnupg"
        ];
      };
    };
    symlinks = [
      {
        host = ".config/VSCodium";
        guest = "config/VSCodium";
      }
      {
        host = ".vscode-oss";
        guest = "data/codium";
      }
    ];
    nativePkgs = pkgs.vscodium;
    hmProgram = {
      name = "vscodium";
      binName = "codium";
    };
  };
}
