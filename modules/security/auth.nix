{
  pkgs,
  config,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.auth";

  nixosConfig = {
    environment.systemPackages = [
      pkgs.doas-sudo-shim
    ];

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
              "nix-collect-garbage"
              "compsize"
              "dmesg"
            ]
          );
      };

      rtkit = {
        enable = true;
      };
    };
  };
}
