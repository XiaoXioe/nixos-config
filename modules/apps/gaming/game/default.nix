{
  pkgs,
  selfLib,
  lib,
  config,
  ...
}:

selfLib.mkModule {
  name = "apps.gaming.game";
  description = "User game settings";

  nixosConfig = {
    hardware.steam-hardware.enable = true;

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

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
      nativePkgs = pkgs.retroarch.withCores (
        cores: with cores; [
          nestopia
          snes9x
          genesis-plus-gx
          mgba
          mupen64plus
          swanstation
          ppsspp
          pcsx2
        ]
      );
      hmProgram = {
        name = "retroarch";
        extraConfig = {
          package = lib.mkIf config.my.apps.gaming.game.flatpaks."org.libretro.RetroArch".flatpak.enable (
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
    home.packages = with pkgs; [
      xwayland-satellite
    ];
    home.sessionVariables = {
      SDL_GAMECONTROLLERCONFIG = "03000000790000000600000010010000,Microntek USB Joystick,crc:79be,platform:Linux,a:b2,b:b1,x:b3,y:b0,dpleft:h0.8,dpright:h0.2,dpup:h0.1,dpdown:h0.4,leftx:a0,lefty:a1,leftstick:b10,rightx:a2,righty:a3,rightstick:b11,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,back:b8,start:b9,steam:2,";
    };
  };
}
