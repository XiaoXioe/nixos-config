{
  config,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.brave";
  description = "Brave browser configuration with maximal performance & privacy";

  hmConfig = {
    programs.brave = {
      enable = true;
      extensions = [
        { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; }
        { id = "nngceckbapebfimnlniiiahkandclblb"; }
        { id = "jplgfhpmjnbigmhklmmbgecoobifkmpa"; }
        { id = "hlepfoohegkhhmjieoechaddaejaokhf"; }
        { id = "lptnjkfjeaemenlipfaaocppmilaeejf"; }
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; }
        { id = "jinjaccalgkegednnccohejagnlnfdag"; }
        { id = "omkfmpieigblcllmkgbflkikinpkodlk"; }
        { id = "jhnleheckmknfcgijgkadoemagpecfol"; }
        { id = "einpaelgookohagofgnnkcfjbkkgepnp"; }
        { id = "nplimhmoanghlebhdiboeellhgmgommi"; }
        { id = "cmpdlhmnmjhihmcfnigoememnffkimlk"; }
      ];
      commandLineArgs = [
        "--force-dark-mode"
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
        "--enable-gpu-rasterization"
        "--ignore-gpu-blocklist"
        "--enable-features=WebUIDarkMode,Containers,VaapiVideoDecoder,VaapiIgnoreDriverChecks"
        "--disable-features=Vulkan,UseChromeOSDirectVideoDecoder,BraveRewards,BraveWallet,BraveVPN,BraveLeo,BraveAI,WebDiscoveryProject"
        "--disable-gpu-driver-bug-workarounds"
        "--disable-reading-from-canvas"
        "--no-pings"
      ];
    };
  };
}
