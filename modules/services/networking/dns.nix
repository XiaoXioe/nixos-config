{
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.networking.dns";

  nixosConfig = {
    # 1. Configuration template
    sops.templates."dnscrypt-proxy.toml" = {
      # Use root as owner to avoid missing-user evaluation errors
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
        listen_address = '127.0.0.1:4200'
        username = "admin"
        password = '${config.sops.placeholder.dnscrypt_monitoring_password}'
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
