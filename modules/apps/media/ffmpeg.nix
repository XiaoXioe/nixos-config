{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.ffmpeg";
  description = "FFmpeg multimedia encoding and processing suite";

  hmConfig = {
    home.packages = with pkgs; [
      ffmpeg
    ];
  };
}
