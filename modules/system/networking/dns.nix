{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.dnscrypt;
in
{
  options.my.services.dnscrypt = {
    enable = selfLib.mkBoolOpt false "dnscrypt-proxy service";
  };

  config = lib.mkIf cfg.enable {
    # 1. Template konfigurasi
    sops.templates."dnscrypt-proxy.toml" = {
      # Gunakan root sebagai owner untuk menghindari error evaluasi user missing
      owner = "root";
      mode = "0444";
      content = ''
        server_names = ['cloudflare', '${config.sops.placeholder.nextdns_name}', 'quad9-dnscrypt-ip4-filter-pri']
        listen_addresses = ['127.0.0.1:53']
        require_dnssec = true
        ipv4_servers = true
        ipv6_servers = false
        block_ipv6 = true
        block_unqualified = true
        block_undelegated = true
        reject_ttl = 10

        # [sources]
        #   [sources.'public-resolvers']
        #   urls = [
        #     'https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md',
        #     'https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md'
        #   ]
        #   cache_file = 'public-resolvers.md'
        #   minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TSmcZ9NcIxtLObnPMpRvM5Q4OPedQJ'

        [monitoring_ui]
        enabled = true
        listen_address = '127.0.0.1:8080'
        username = ""
        password = ""
        tls_certificate = ""
        tls_key = ""
        enable_query_log = true
        privacy_level = 0

        [static.'${config.sops.placeholder.nextdns_name}']
        stamp = '${config.sops.placeholder.nextdns_stamp}'
      '';
    };

    services.dnscrypt-proxy = {
      enable = true;
      configFile = config.sops.templates."dnscrypt-proxy.toml".path;
    };

    services.resolved.enable = false;
    networking = {
      nameservers = [ "127.0.0.1" ];
      networkmanager.dns = "none";
      dhcpcd.extraConfig = "nohook resolv.conf";
    };
  };
}
