{
  pkgs,
  selfLib,
  lib,
  config,
  ...
}:

let
  retroarchCores =
    cores: with cores; [
      nestopia
      snes9x
      genesis-plus-gx
      mgba
      mupen64plus
      swanstation
    ];
in
selfLib.mkModule {
  name = "apps.gaming.emulators";
  description = "Console emulators and gaming clients (RetroArch, Dolphin, PPSSPP, PCSX2, Sober)";

  flatpakCfg = {
    "org.vinegarhq.Sober" = {
      enable = true;
      binName = "sober";
    };

    "org.libretro.RetroArch" = {
      enable = true;
      overrides = {
        Context = {
          filesystems = [
            "/mnt/data"
          ];
        };
      };
      symlinks = [
        {
          host = ".config/retroarch";
          guest = "config/retroarch";
        }
      ];
      nativePkgs = pkgs.retroarch.withCores retroarchCores;
      hmProgram = {
        name = "retroarch";
        extraConfig = {
          package =
            lib.mkIf config.my.apps.gaming.emulators.flatpaks."org.libretro.RetroArch".flatpak.enable
              (
                lib.mkForce (
                  (pkgs.runCommand "empty-retroarch" { } "mkdir -p $out")
                  // {
                    wrapper = _: pkgs.runCommand "empty-retroarch-wrapped" { } "mkdir -p $out";
                  }
                )
              );
          settings = {
            "video_driver" = "gl";
            "audio_driver" = "pulse";
            "input_joypad_driver" = "udev";
            "fps_show" = "true";
            "menu_swap_ok_cancel_buttons" = "true";
            "input_menu_toggle_gamepad_combo" = "4";
            "video_threaded" = "true";
            "quit_press_twice" = "true";
            "savestate_auto_save" = "true";
            "savestate_auto_load" = "true";
            "notification_show_autoconfig" = "false";
          };
        };
      };
    };

    "org.DolphinEmu.dolphin-emu" = {
      enable = true;
      flatpak = false;
      overrides = {
        Context = {
          filesystems = [
            "/mnt/data"
          ];
        };
      };
      symlinks = [
        {
          host = ".local/share/dolphin-emu";
          guest = "data/dolphin-emu";
        }
        {
          host = ".config/dolphin-emu";
          guest = "config/dolphin-emu";
        }
      ];
      nativePkgs = pkgs.dolphin-emu;
    };

    "org.ppsspp.PPSSPP" = {
      enable = true;
      overrides = {
        Context = {
          filesystems = [
            "/mnt/data"
          ];
        };
      };
      symlinks = [
        {
          host = ".config/ppsspp";
          guest = "config/ppsspp";
        }
      ];
      nativePkgs = pkgs.ppsspp;
    };

    "net.pcsx2.PCSX2" = {
      enable = true;
      overrides = {
        Context = {
          filesystems = [
            "/mnt/data"
          ];
        };
      };
      symlinks = [
        {
          host = ".config/PCSX2";
          guest = "config/PCSX2";
        }
      ];
      nativePkgs = pkgs.pcsx2;
    };
  };

  hmConfig = hmOpts: {
    home.file.".config/retroarch/cores" = {
      source =
        let
          coresJoined = pkgs.symlinkJoin {
            name = "retroarch-cores";
            paths = retroarchCores pkgs.libretro;
          };
        in
        "${coresJoined}/lib/retroarch/cores";
      force = true;
    };

    xdg.configFile."dolphin-emu/Dolphin.ini" = {
      text = lib.generators.toINI { } {
        Core = {
          CPUThread = "True";
          DSPHLE = "True";
          GFXBackend = "OGL";
        };
        General = {
          ISOPaths = 1;
          ISOPath0 = "/mnt/data/Games-retro/gamecube";
          RecursiveISOPaths = "True";
        };
        Analytics = {
          PermissionAsked = "True";
        };
      };
      force = true;
    };

    xdg.configFile."dolphin-emu/GFX.ini" = {
      text = lib.generators.toINI { } {
        Settings = {
          AspectRatio = 1;
          BackendMultithreading = "True";
          FastDepthCalculation = "True";
          InternalResolution = 2;
          ShaderCompilationMode = 2;
        };
      };
      force = true;
    };

    xdg.configFile."dolphin-emu/GCPadNew.ini" = {
      text = lib.generators.toINI { } {
        GCPad1 = {
          Device = "evdev/0/Microntek              USB Joystick";
          "Buttons/A" = "`Button 2`";
          "Buttons/B" = "`Button 3`";
          "Buttons/X" = "`Button 1`";
          "Buttons/Y" = "`Button 0`";
          "Buttons/Z" = "`Button 8`";
          "Buttons/Start" = "`Button 9`";
          "Main Stick/Up" = "`Axis 1-`";
          "Main Stick/Down" = "`Axis 1+`";
          "Main Stick/Left" = "`Axis 0-`";
          "Main Stick/Right" = "`Axis 0+`";
          "Main Stick/Modifier" = "`Button 10`";
          "Main Stick/Calibration" = "100.00 141.42 100.00 141.42 100.00 141.42 100.00 141.42";
          "C-Stick/Up" = "`Axis 3-`";
          "C-Stick/Down" = "`Axis 3+`";
          "C-Stick/Left" = "`Axis 2-`";
          "C-Stick/Right" = "`Axis 2+`";
          "C-Stick/Modifier" = "`Button 11`";
          "C-Stick/Calibration" = "100.00 141.42 100.00 141.42 100.00 141.42 100.00 141.42";
          "Triggers/L" = "`Button 6`";
          "Triggers/R" = "`Button 7`";
          "Triggers/L-Analog" = "`Button 4`";
          "Triggers/R-Analog" = "`Button 5`";
          "D-Pad/Up" = "`Axis 5-`";
          "D-Pad/Down" = "`Axis 5+`";
          "D-Pad/Left" = "`Axis 4-`";
          "D-Pad/Right" = "`Axis 4+`";
        };
        GCPad2 = {
          Device = "XInput2/0/Virtual core pointer";
        };
        GCPad3 = {
          Device = "XInput2/0/Virtual core pointer";
        };
        GCPad4 = {
          Device = "XInput2/0/Virtual core pointer";
        };
      };
      force = true;
    };
  };
}
