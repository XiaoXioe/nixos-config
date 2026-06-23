{
  pkgs,
  config,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.hardening";

  nixosConfig = {
    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
    };

    environment.systemPackages = [
      pkgs.doas-sudo-shim
    ];

    services = {
      fail2ban = {
        enable = true;
        ignoreIP = [
          "127.0.0.0/8"
          "192.168.0.0/16"
        ];
      };
    };

    security = {

      sudo.enable = false;

      doas = {
        enable = true;
        extraRules =
          let
            adminUsers = [ config.my.user.name ];
          in
          [
            {
              users = adminUsers;
              keepEnv = true;
              persist = true;
            }
          ]
          ++ (map
            (cmd: {
              users = adminUsers;
              noPass = true;
              keepEnv = true;
              cmd = cmd;
            })
            [
              "nix"
              "nixos-rebuild"
              "nix-collect-garbage"
              "compsize"
              "dmesg"
              "pkill"
              "systemctl"
            ]
          );
      };

      rtkit = {
        enable = true;
      };

      apparmor = {
        enable = true;
        enableCache = true;
        packages = [ pkgs.apparmor-profiles ];
      };
    };
  };
}
