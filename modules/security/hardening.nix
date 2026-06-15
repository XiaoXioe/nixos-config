{
  pkgs,
  config,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.hardening";

  nixosConfig = {
    services = {
      fail2ban = {
        enable = false;
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
