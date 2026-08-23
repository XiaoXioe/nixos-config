{
  pkgs,
  selfLib,
  lib,
  ...
}:

let
  pcsx2Info = selfLib.appVersions.pcsx2;
  ppssppInfo = selfLib.appVersions.ppsspp;
  retroarchInfo = selfLib.appVersions.retroarch;
  retroarchCoresInfo = selfLib.appVersions.retroarch-cores;

  ppssppIcon = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/hrydgard/ppsspp/master/source_assets/image/icon_regular.png";
    sha256 = "073mnmc2jimn9dr99zm5j07ys27harrclzq21flvk0xsr2d3nlxa";
  };

  ppssppDesktopItem = pkgs.makeDesktopItem {
    name = "ppsspp";
    desktopName = "PPSSPP";
    genericName = "PSP Emulator";
    comment = "Sony PlayStation Portable emulator";
    exec = "ppsspp %f";
    icon = "ppsspp";
    terminal = false;
    type = "Application";
    categories = [
      "Game"
      "Emulator"
    ];
    mimeTypes = [
      "application/x-iso9660-appimage"
      "application/x-cso"
    ];
  };

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

  retroarchRaw = (selfLib.mkNativeApp pkgs) {
    name = "retroarch";
    inherit (retroarchInfo) version;
    src = selfLib.fetchApp pkgs "retroarch";
    execPath = "RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage";
    binName = "retroarch";
  };

  retroarchHome = "${retroarchRaw.unwrapped}/opt/retroarch/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch";

  retroarchAppendCfg = pkgs.writeText "retroarch-append.cfg" ''
    assets_directory = "${retroarchHome}/assets"
    joypad_autoconfig_dir = "${retroarchHome}/autoconfig"
    cursor_directory = "${retroarchHome}/database/cursors"
    cheat_database_path = "${retroarchHome}/database/cht"
    content_database_path = "${retroarchHome}/database/rdb"
    video_shader_dir = "${retroarchHome}/shaders"
    overlay_directory = "${retroarchHome}/overlays"
    video_filter_dir = "${retroarchHome}/filters"
    libretro_directory = "${retroarchCores}/lib/retroarch/cores"
    libretro_info_path = "${retroarchCores}/lib/retroarch/cores"
    menu_driver = "ozone"
  '';

  retroarchDesktopItem = pkgs.makeDesktopItem {
    name = "retroarch";
    desktopName = "RetroArch";
    genericName = "Frontend for emulators, game engines and media players";
    comment = "Multi-system game and emulator frontend";
    exec = "retroarch %U";
    icon = "retroarch";
    terminal = false;
    type = "Application";
    categories = [
      "Game"
      "Emulator"
    ];
    mimeTypes = [ "x-scheme-handler/retroarch" ];
  };

  retroarchNative =
    ((selfLib.mkNativeApp pkgs) {
      name = "retroarch";
      inherit (retroarchInfo) version;
      src = selfLib.fetchApp pkgs "retroarch";
      execPath = "RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage";
      binName = "retroarch";
      desktopItem = retroarchDesktopItem;
      extraArgs = [
        "--appendconfig"
        "${retroarchAppendCfg}"
      ];
      extraPostInstall = ''
        mkdir -p "$out/share/pixmaps" "$out/share/icons/hicolor/256x256/apps"
        cp -f "${retroarchHome}/assets/ozone/png/icons/retroarch.png" "$out/share/pixmaps/retroarch.png" 2>/dev/null || true
        cp -f "${retroarchHome}/assets/ozone/png/icons/retroarch.png" "$out/share/icons/hicolor/256x256/apps/retroarch.png" 2>/dev/null || true
      '';
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
    extraLibs = [
      pkgs.gmp
      pkgs.libgpg-error
      (lib.getLib pkgs.e2fsprogs)
      pkgs.libsm
      pkgs.libice
      pkgs.libglvnd
      (lib.getLib pkgs.krb5)
      pkgs.libunwind
    ];
    extraEnv = {
      QT_PLUGIN_PATH = "${pcsx2Native.unwrapped}/opt/pcsx2/usr/plugins";
    };
    extraWrapperArgs = [
      "--prefix LD_LIBRARY_PATH : ${pcsx2Native.unwrapped}/opt/pcsx2/usr/lib"
      "--prefix NIX_LD_LIBRARY_PATH : ${pcsx2Native.unwrapped}/opt/pcsx2/usr/lib"
    ];
  };

  ppssppNative = (selfLib.mkNativeApp pkgs) {
    name = "ppsspp";
    inherit (ppssppInfo) version;
    src = selfLib.fetchApp pkgs "ppsspp";
    execPath = "PPSSPP";
    binName = "ppsspp";
    desktopItem = ppssppDesktopItem;
    extraPostInstall = ''
      mkdir -p "$out/share/pixmaps" "$out/share/icons/hicolor/512x512/apps"
      cp -f "${ppssppIcon}" "$out/share/pixmaps/ppsspp.png"
      cp -f "${ppssppIcon}" "$out/share/icons/hicolor/512x512/apps/ppsspp.png"
    '';
  };

  dolphinNative = pkgs.dolphin-emu;
in
selfLib.mkModule {
  name = "apps.gaming.emulators";
  description = "Console emulators and gaming clients (RetroArch, Dolphin, PPSSPP, PCSX2) with pure upstream binaries";

  hmConfig =
    hmOpts:
    let
      dataPath = hmOpts.osConfig.my.dataPath;
    in
    {
      home.packages = [
        retroarchNative
        pcsx2Native
        ppssppNative
        dolphinNative
      ];

      programs.retroarch = {
        enable = true;
        package = retroarchNative;
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
          "content_directory" = "${dataPath}/Emulation/Roms";
          "savefile_directory" = "~/.local/share/retroarch/saves";
          "savestate_directory" = "~/.local/share/retroarch/states";
          "system_directory" = "${dataPath}/Emulation/Bios";
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
