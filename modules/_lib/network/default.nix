# Network / WARP helpers: static proxy env-vars and connection wait script.
{
  pkgs,
  ...
}:

{
  warpProxyEnv = {
    HTTP_PROXY = "socks5h://127.0.0.1:40000";
    HTTPS_PROXY = "socks5h://127.0.0.1:40000";
    ALL_PROXY = "socks5h://127.0.0.1:40000";
    NO_PROXY = "localhost,127.0.0.1,::1";
  };

  mkWarpWaitScript =
    scriptName:
    pkgs.writeShellScript scriptName ''
      # Wait for SOCKS5 proxy port 40000 to be online and working
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --max-time 3 -o /dev/null --proxy socks5h://127.0.0.1:40000 https://www.google.com; then
          echo "Proxy 40000 is online."
          exit 0
        fi
        ${pkgs.coreutils}/bin/sleep 2
      done
      echo "WARNING: Proxy 40000 not responsive after 60s, proceeding anyway..."
    '';
}
