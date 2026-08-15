{
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.networking.dns";

  nixosConfig = {
    sops.secrets = builtins.mapAttrs (_: value: { sopsFile = ./secrets.yaml; } // value) {
      "rethinkdns_stamp" = {
      };
      "nextdns_stamp" = {
      };
      "nextdns_name" = {
      };
      "dnscrypt_monitoring_password" = {
      };
      "nextdns_ip1" = {
        owner = config.my.user.name;
      };
      "nextdns_ip2" = {
        owner = config.my.user.name;
      };
    };

    # 1. Configuration template
    sops.templates."dnscrypt-proxy.toml" = {
      # Use root:keys to avoid missing-user evaluation errors while restricting read access
      owner = "root";
      group = "keys";
      mode = "0440";
      content = ''
        server_names = ['${config.sops.placeholder.nextdns_name}', 'rethinkdns', 'quad9-dnscrypt-ip4-filter-pri']
        lb_strategy = 'first'
        listen_addresses = ['127.0.0.1:53']
        require_dnssec = true
        ipv4_servers = true
        ipv6_servers = false
        block_ipv6 = true
        block_unqualified = true
        block_undelegated = true
        reject_ttl = 10
        timeout = 5000

        # Daftar resolver publik — wajib aktif agar 'quad9-dnscrypt-ip4-filter-pri'
        # bisa di-resolve sebagai fallback ketika NextDNS (entry [static]) down.
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

        # RethinkDNS via SOPS secret placeholder
        [static.'rethinkdns']
        stamp = '${config.sops.placeholder.rethinkdns_stamp}'
      '';
    };

    services.dnscrypt-proxy = {
      enable = true;
      configFile = config.sops.templates."dnscrypt-proxy.toml".path;
    };

    systemd.services.dnscrypt-proxy = {
      onFailure = [ "status-alert@dnscrypt-proxy.service" ];
      serviceConfig.SupplementaryGroups = [ "keys" ];
    };

    services.resolved.enable = false;
    networking = {
      nameservers = [ "127.0.0.1" ];
      networkmanager.dns = "none";
      dhcpcd.extraConfig = "nohook resolv.conf";
    };
  };
}
