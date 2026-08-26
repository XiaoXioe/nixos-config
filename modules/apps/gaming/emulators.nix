{
  pkgs,
  selfLib,
  lib,
  ...
}:

let
  pcsx2Pkg = selfLib.fetchCachePinned "pcsx2";
  ppssppPkg = selfLib.fetchCachePinned "ppsspp";
  dolphinPkg = selfLib.fetchCachePinned "dolphin_emu";
  retroarchPkg = (selfLib.fetchCachePinned pkgs "retroarch_bare") // {
    wrapper = pkgs.retroarch-bare.wrapper;
  };
in
selfLib.mkModule {
  name = "apps.gaming.emulators";
  description = "Console emulators and gaming clients (RetroArch, Dolphin, PPSSPP, PCSX2)";

  hmConfig =
    hmOpts:
    let
      dataPath = hmOpts.osConfig.my.dataPath;
    in
    {
      home.packages = [
        pcsx2Pkg
        ppssppPkg
        dolphinPkg
      ];

      programs.retroarch = {
        enable = true;
        package = retroarchPkg;
        cores = {
          # PlayStation 1 (psx/)
          swanstation.enable = true;
          beetle-psx.enable = true;
          beetle-psx-hw.enable = true;
          pcsx_rearmed.enable = true;

          # Super Nintendo (snes/)
          snes9x.enable = true;
          bsnes.enable = true;

          # Sega Genesis / Mega Drive (genesis/)
          genesis-plus-gx.enable = true;
          picodrive.enable = true;

          # Nintendo Entertainment System (nes/)
          nestopia.enable = true;
          fceumm.enable = true;

          # Nintendo DS (nds/)
          melonds.enable = true;
          desmume.enable = true;

          # Atari 2600 (atari2600/)
          stella.enable = true;

          # Game Boy Advance / Color / Classic
          mgba.enable = true;
          gambatte.enable = true;
          sameboy.enable = true;

          # Nintendo 64 & Arcade / Dreamcast
          mupen64plus.enable = true;
          fbneo.enable = true;
          flycast.enable = true;
        };
        settings = {
          # Antarmuka dan driver
          "video_driver" = "gl";
          "audio_driver" = "pulse";
          "input_joypad_driver" = "udev";
          "fps_show" = "true";
          "menu_swap_ok_cancel_buttons" = "true";
          "input_menu_toggle_gamepad_combo" = "4";
          "config_save_on_exit" = "false";
          "video_threaded" = "true";
          "quit_press_twice" = "true";
          "savestate_auto_save" = "true";
          "savestate_auto_load" = "true";
          "notification_show_autoconfig" = "false";

          # Direktori konten game dan BIOS
          "content_directory" = "${dataPath}/Games-retro";
          "savefile_directory" = "~/.local/share/retroarch/saves";
          "savestate_directory" = "~/.local/share/retroarch/states";
          "system_directory" = "${dataPath}/Games-retro/bios";
        };
      };

      xdg.configFile = {
        "dolphin-emu/Dolphin.ini" = {
          text = lib.generators.toINI { } {
            Core = {
              CPUThread = "True";
              DSPHLE = "True";
              GFXBackend = "OGL";
            };
            General = {
              ISOPaths = 2;
              ISOPath0 = "${dataPath}/Games-retro/gamecube";
              ISOPath1 = "${dataPath}/Games-retro/wii";
              RecursiveISOPaths = "True";
            };
            Controls = {
              WiimoteSource0 = 1;
              WiimoteSource1 = 0;
              WiimoteSource2 = 0;
              WiimoteSource3 = 0;
            };
            Analytics = {
              PermissionAsked = "True";
            };
          };
          force = true;
        };

        "dolphin-emu/GFX.ini" = {
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

        "dolphin-emu/WiimoteNew.ini" = {
          text = lib.generators.toINI { } {
            Wiimote1 = {
              Device = "evdev/0/Microntek              USB Joystick";
              "Buttons/A" = "`Button 2`";
              "Buttons/B" = "`Button 3`";
              "Buttons/1" = "`Button 0`";
              "Buttons/2" = "`Button 1`";
              "Buttons/-" = "`Button 8`";
              "Buttons/+" = "`Button 9`";
              "Buttons/Home" = "`Button 10`";

              "D-Pad/Up" = "`Axis 5-`";
              "D-Pad/Down" = "`Axis 5+`";
              "D-Pad/Left" = "`Axis 4-`";
              "D-Pad/Right" = "`Axis 4+`";

              "IR/Up" = "`Axis 3-`";
              "IR/Down" = "`Axis 3+`";
              "IR/Left" = "`Axis 2-`";
              "IR/Right" = "`Axis 2+`";

              "Shake/X" = "`Button 4`";
              "Shake/Y" = "`Button 5`";
              "Shake/Z" = "`Button 5`";

              "Extension/Attach" = "Nunchuk";
              "Nunchuk/Buttons/C" = "`Button 6`";
              "Nunchuk/Buttons/Z" = "`Button 7`";
              "Nunchuk/Stick/Up" = "`Axis 1-`";
              "Nunchuk/Stick/Down" = "`Axis 1+`";
              "Nunchuk/Stick/Left" = "`Axis 0-`";
              "Nunchuk/Stick/Right" = "`Axis 0+`";
            };
          };
          force = true;
        };

        "dolphin-emu/GCPadNew.ini" = {
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
    };
}
