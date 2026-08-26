{
  config,
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  userName = config.my.user.name;
  pkg = inputs.nix-mcp.packages.${system}.free-search-mcp;
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
      # Integrasi browser Chromium sistem dari modules/apps/browsers/chromium.nix
      CHROME_BIN = "/etc/profiles/per-user/${userName}/bin/chromium";
      CHROMIUM_PATH = "/etc/profiles/per-user/${userName}/bin/chromium";
      PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "/etc/profiles/per-user/${userName}/bin/chromium";
    };
  };

  # Direktori di RAM disiapkan oleh systemd tmpfiles
  systemdTmpfilesRules = [
    "d /run/user/1000/search-mcp 0700 ${userName} users - -"
    "d /run/user/1000/search-mcp/downloads 0700 ${userName} users - -"
  ];
}
