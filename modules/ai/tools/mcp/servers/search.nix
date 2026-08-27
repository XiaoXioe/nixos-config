{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  userName = config.my.user.name;
  pkg = inputs.nix-mcp.packages.${system}.free-search-mcp;

  chromiumBin =
    if (config.my.apps.browsers.chromium.enable or false) then
      "/etc/profiles/per-user/${userName}/bin/chromium"
    else if (config.my.apps.browsers.brave.enable or false) then
      "/etc/profiles/per-user/${userName}/bin/brave"
    else
      null;
in
{
  name = "search";

  commonSpec = {
    command = "${pkg}/bin/free-search-mcp";
    args = [ ];
    env = {
      # Arahkan cache SQLite dan download ke tmpfs/RAM (tanpa membebani disk)
      SEARCH_MCP_CACHE_DIR = "/run/user/1000/search-mcp";
      SEARCH_MCP_DOWNLOAD_DIR = "/run/user/1000/search-mcp/downloads";
    }
    // lib.optionalAttrs (chromiumBin != null) {
      CHROME_BIN = chromiumBin;
      CHROMIUM_PATH = chromiumBin;
      PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = chromiumBin;
    };
  };

  # Direktori di RAM disiapkan oleh systemd tmpfiles
  systemdTmpfilesRules = [
    "d /run/user/1000/search-mcp 0700 ${userName} users - -"
    "d /run/user/1000/search-mcp/downloads 0700 ${userName} users - -"
  ];
}
