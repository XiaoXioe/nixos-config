{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.gaming.game";
  description = "User game settings";

  hmConfig = {
    home.packages = with pkgs; [ xwayland-satellite ppsspp pcsx2 ];
    home.sessionVariables = {
      SDL_GAMECONTROLLERCONFIG = "03000000790000000600000010010000,Microntek USB Joystick,crc:79be,platform:Linux,a:b2,b:b1,x:b3,y:b0,dpleft:h0.8,dpright:h0.2,dpup:h0.1,dpdown:h0.4,leftx:a0,lefty:a1,leftstick:b10,rightx:a2,righty:a3,rightstick:b11,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,back:b8,start:b9,steam:2,";
    };
    programs.retroarch = {
      enable = true;
      cores = { nestopia.enable = true; snes9x.enable = true; "genesis-plus-gx".enable = true; mgba.enable = true; mupen64plus.enable = true; swanstation.enable = true; ppsspp.enable = true; pcsx2.enable = true; };
      settings = {
        "video_driver" = "gl"; "audio_driver" = "pulse"; "input_joypad_driver" = "udev"; "fps_show" = "true"; "menu_swap_ok_cancel_buttons" = "true";
        "input_menu_toggle_gamepad_combo" = "4"; "video_threaded" = "true"; "quit_press_twice" = "true"; "savestate_auto_save" = "true"; "savestate_auto_load" = "true"; "notification_show_autoconfig" = "false";
      };
    };
  };
}
