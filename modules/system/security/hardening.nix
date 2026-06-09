{
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.security.hardening;
in
{
  options.my.system.security.hardening = {
    enable = lib.mkEnableOption "system security configuration" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
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
      # sudo-rs (rust)
      sudo-rs = {
        enable = true;
        execWheelOnly = true;
        extraConfig = ''
          # Show asterisks when typing password
          Defaults env_reset,pwfeedback

          # Extend sudo session timeout to 30 minutes (default is 15)
          Defaults timestamp_timeout=30
        '';

        extraRules = [
          {
            users = [
              config.my.user.name
            ];
            commands = [
              {
                command = "/run/current-system/sw/bin/compsize";
                options = [ "NOPASSWD" ];
              }
              {
                command = "/run/current-system/sw/bin/dmesg";
                options = [ "NOPASSWD" ];
              }
              {
                command = "/run/current-system/sw/bin/pkill";
                options = [ "NOPASSWD" ];
              }
              {
                command = "/run/current-system/sw/bin/systemctl";
                options = [ "NOPASSWD" ];
              }
              {
                command = "/run/current-system/sw/bin/nixos-rebuild";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];
      };

      rtkit = {
        enable = true;
      };

      # apparmor = {
      #   enable = true;
      #   enableCache = true;
      #   packages = [ pkgs.apparmor-profiles ];
      # };

    };
  };
}
