{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.gaming.game";
  description = "User game settings (controllers and system integrations)";

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      xwayland-satellite
    ];
    home.sessionVariables = {
      SDL_GAMECONTROLLERCONFIG = "03000000790000000600000010010000,Microntek USB Joystick,crc:79be,platform:Linux,a:b2,b:b1,x:b3,y:b0,dpleft:h0.8,dpright:h0.2,dpup:h0.1,dpdown:h0.4,leftx:a0,lefty:a1,leftstick:b10,rightx:a2,righty:a3,rightstick:b11,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,back:b8,start:b9,steam:2,";
    };
  };
}
