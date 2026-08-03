{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.ffmpeg";
  description = "FFmpeg multimedia encoding and processing suite";

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      ffmpeg
    ];
  };
}
