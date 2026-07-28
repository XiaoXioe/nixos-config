{ pkgs }:

{
  "com.vscodium.codium" = {
    enable = true;
    overrides = {
      Context.filesystems = [
        "host"
        "/tmp"
        "xdg-run/bus"
        "xdg-run/gnupg"
      ];
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
