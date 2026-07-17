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
      # Use root:keys to avoid missing-user evaluation errors while restricting read access
      owner = "root";
      group = "keys";
      mode = "0440";
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

        # Daftar resolver publik — wajib aktif agar 'cloudflare' dan
        # 'quad9-dnscrypt-ip4-filter-pri' bisa di-resolve sebagai fallback
        # ketika NextDNS (entry [static]) down.
        [sources]
          [sources.'public-resolvers']
          urls = [
            'https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md',
            'https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md'
          ]
          cache_file = '/run/dnscrypt-proxy/public-resolvers.md'
          minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3'

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

    systemd.services.dnscrypt-proxy.serviceConfig.SupplementaryGroups = [ "keys" ];

    services.resolved.enable = false;
    networking = {
      nameservers = [ "127.0.0.1" ];
      networkmanager.dns = "none";
      dhcpcd.extraConfig = "nohook resolv.conf";
    };
  };
}
