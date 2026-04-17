{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.security;
in
{
  options.my.system.security = {
    enable = selfLib.mkBoolOpt false "system security configuration";
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
          # Memunculkan bintang saat mengetik password
          Defaults env_reset,pwfeedback

          # Memperpanjang batas waktu sesi sudo menjadi 30 menit (default biasanya 15)
          Defaults timestamp_timeout=30
        '';

        extraRules = [
          {
            users = [
              "klein-moretti"
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
      #   # killUnconfinedConfinables = true;
      #   packages = [ pkgs.apparmor-profiles ];
      # };

    };
  };
}
