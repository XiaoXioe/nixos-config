# Network / WARP helpers: static proxy env-vars and connection wait script.
_:

{
  # Static proxy environment variables set for WARP / SOCKS5 proxy
  # Usage: selfLib.warpProxyEnv 40000
  warpProxyEnv = port: {
    HTTP_PROXY = "socks5h://127.0.0.1:${toString port}";
    HTTPS_PROXY = "socks5h://127.0.0.1:${toString port}";
    ALL_PROXY = "socks5h://127.0.0.1:${toString port}";
    NO_PROXY = "localhost,127.0.0.1,::1";
  };

  # Script generator to block until a WARP / SOCKS5 proxy port becomes reachable
  # Usage: selfLib.mkWarpWaitScript pkgs 40000 "wait-warp"
  mkWarpWaitScript =
    pkgs: port: scriptName:
    pkgs.writeShellScript scriptName ''
      # Wait for SOCKS5 proxy port ${toString port} to be online and working
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --max-time 3 -o /dev/null --proxy socks5h://127.0.0.1:${toString port} https://www.google.com; then
          echo "Proxy ${toString port} is online."
          exit 0
        fi
        ${pkgs.coreutils}/bin/sleep 2
      done
      echo "WARNING: Proxy ${toString port} not responsive after 60s, proceeding anyway..."
    '';
}
