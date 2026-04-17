{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.gamemode;

  # Gunakan coreutils untuk memastikan echo dan tee selalu tersedia
  coreutils = pkgs.coreutils;

  # Script untuk MELEPAS batas CPU
  gameModeStart = pkgs.writeShellScriptBin "gamemode-start" ''
    ${coreutils}/bin/echo 3900000 | ${coreutils}/bin/tee /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq > /dev/null
  '';

  # Script untuk MENGUNCI KEMBALI batas CPU
  gameModeEnd = pkgs.writeShellScriptBin "gamemode-end" ''
    ${coreutils}/bin/echo 1600000 | ${coreutils}/bin/tee /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq > /dev/null
  '';
in
{
  options.my.services.gamemode = {
    enable = selfLib.mkBoolOpt false "GameMode dengan manajemen CPU frequency otomatis";

    maxFreqKHz = lib.mkOption {
      type = lib.types.int;
      default = 3900000;
      description = "Batas maksimum CPU frequency saat mode gaming aktif (dalam kHz).";
    };

    idleFreqKHz = lib.mkOption {
      type = lib.types.int;
      default = 1600000;
      description = "Batas CPU frequency saat idle / normal (dalam kHz).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "klein-moretti";
      description = "User yang diberi izin sudo tanpa password untuk menjalankan script gamemode.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Kunci CPU di frekuensi hemat setiap kali sistem booting
    # (gunakan systemd service karena tmpfiles tidak mendukung glob path)
    systemd.services.cpu-freq-idle = {
      description = "Set CPU max frequency to idle limit on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo ${toString cfg.idleFreqKHz} | tee /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq > /dev/null'";
      };
    };

    # Izinkan user menjalankan kedua script tanpa password sudo
    security.sudo-rs.extraRules = [
      {
        users = [ cfg.user ];
        commands = [
          {
            command = "${gameModeStart}/bin/gamemode-start";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${gameModeEnd}/bin/gamemode-end";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];


    programs.gamemode = {
      enable = true;
      settings = {
        general = {
          # Berhenti mencoba mematikan split_lock
          disable_splitlock = 0;

          # Berhenti mencoba mengubah governor (karena kita sudah urus GHz-nya manual)
          desiredgov = "schedutil";
        };
        custom = {
          start = "/run/wrappers/bin/sudo ${gameModeStart}/bin/gamemode-start";
          end = "/run/wrappers/bin/sudo ${gameModeEnd}/bin/gamemode-end";
        };
      };
    };
  };
}
