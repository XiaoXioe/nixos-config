{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "security.auth.rtkit";
  description = "RealtimeKit daemon for scheduling privileges";

  nixosConfig = {
    security.rtkit.enable = true;
  };
}
