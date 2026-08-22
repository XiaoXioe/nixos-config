{
  pkgs,
  selfLib,
  lib,
  ...
}:

let
  pcsx2Info = selfLib.appVersions.pcsx2;
  ppssppInfo = selfLib.appVersions.ppsspp;
  dolphinInfo = selfLib.appVersions.dolphin-emu;
  retroarchInfo = selfLib.appVersions.retroarch;
  retroarchCoresInfo = selfLib.appVersions.retroarch-cores;

  retroarchCores = pkgs.stdenv.mkDerivation {
    name = "retroarch-cores";
    inherit (retroarchCoresInfo) version;
    src = selfLib.fetchApp pkgs "retroarch-cores";
    nativeBuildInputs = [ pkgs.p7zip ];
    dontStrip = true;
    dontPatchELF = true;
    unpackPhase = ''
      runHook preUnpack
      7z x "$src"
      runHook postUnpack
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/retroarch/cores"
      cp -r RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/cores/* "$out/lib/retroarch/cores/"
      runHook postInstall
    '';
  };

  retroarchNative =
    ((selfLib.mkNativeApp pkgs) {
      name = "retroarch";
      inherit (retroarchInfo) version;
      src = selfLib.fetchApp pkgs "retroarch";
      execPath = "RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage";
      binName = "retroarch";
    })
    // {
      wrapper = _: retroarchNative;
    };

  pcsx2Native = (selfLib.mkNativeApp pkgs) {
    name = "pcsx2";
    inherit (pcsx2Info) version;
    src = selfLib.fetchApp pkgs "pcsx2";
    execPath = "usr/bin/pcsx2-qt";
    binName = "pcsx2";
  };

  ppssppNative = (selfLib.mkNativeApp pkgs) {
    name = "ppsspp";
    inherit (ppssppInfo) version;
    src = selfLib.fetchApp pkgs "ppsspp";
    execPath = "PPSSPP";
    binName = "ppsspp";
  };

  dolphinNative = (selfLib.mkNativeApp pkgs) {
    name = "dolphin-emu";
    inherit (dolphinInfo) version;
    src = selfLib.fetchApp pkgs "dolphin-emu";
    execPath = "usr/games/dolphin-emu";
    binName = "dolphin-emu";
  };
in
selfLib.mkModule {
  name = "apps.gaming.emulators";
  description = "Console emulators and gaming clients (RetroArch, Dolphin, PPSSPP, PCSX2) with pure upstream binaries";

  hmConfig =
    hmOpts:
    let
      dataPath = hmOpts.osConfig.my.dataPath;
      retroarchHome = "${retroarchNative}/opt/retroarch/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch";
    in
    {
      home.packages = [
        pcsx2Native
        ppssppNative
        dolphinNative
      ];

      programs.retroarch = {
        enable = true;
        package = retroarchNative;
        settings = {
          # Path asset tema (Ozone/XMB), icon, database, autoconfig, shaders
          "assets_directory" = "${retroarchHome}/assets";
          "joypad_autoconfig_dir" = "${retroarchHome}/autoconfig";
          "cursor_directory" = "${retroarchHome}/database/cursors";
          "cheat_database_path" = "${retroarchHome}/database/cht";
          "content_database_path" = "${retroarchHome}/database/rdb";
          "video_shader_dir" = "${retroarchHome}/shaders";
          "overlay_directory" = "${retroarchHome}/overlays";
          "video_filter_dir" = "${retroarchHome}/filters";
          "libretro_directory" = "${retroarchCores}/lib/retroarch/cores";
          "libretro_info_path" = "${retroarchCores}/lib/retroarch/cores";

          # Antarmuka dan driver
          "menu_driver" = "ozone";
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
          "content_directory" = "${dataPath}/Emulation/Roms";
          "savefile_directory" = "~/.local/share/retroarch/saves";
          "savestate_directory" = "~/.local/share/retroarch/states";
          "system_directory" = "${dataPath}/Emulation/Bios";
        };
      };

      home.file = {
        ".config/retroarch/cores" = {
          source = "${retroarchCores}/lib/retroarch/cores";
          force = true;
        };
        ".config/retroarch/assets" = {
          source = "${retroarchHome}/assets";
          force = true;
        };
        ".config/retroarch/autoconfig" = {
          source = "${retroarchHome}/autoconfig";
          force = true;
        };
        ".config/retroarch/overlays" = {
          source = "${retroarchHome}/overlays";
          force = true;
        };
        ".config/retroarch/shaders" = {
          source = "${retroarchHome}/shaders";
          force = true;
        };
        ".config/retroarch/database" = {
          source = "${retroarchHome}/database";
          force = true;
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
