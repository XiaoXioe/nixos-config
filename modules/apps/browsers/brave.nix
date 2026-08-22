{
  selfLib,
  pkgs,
  ...
}:

let
  inherit (selfLib.browserAddonsFor { inherit pkgs; }) commonChromiumExtensions;
  appInfo = selfLib.appVersions.brave;

  braveNative = (selfLib.mkNativeApp pkgs) {
    name = "brave";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "brave";
    execPath = "opt/brave.com/brave/brave";
    binName = "brave";
    extraArgs = [
      "--password-store=gnome-libsecret"
      "--enable-gpu-rasterization"
      "--ignore-gpu-blocklist"
      "--enable-features=WebUIDarkMode,Containers"
      "--disable-gpu-driver-bug-workarounds"
      "--disable-reading-from-canvas"
      "--no-pings"
    ];
  };
in
selfLib.mkModule {
  name = "apps.browsers.brave";
  description = "Brave browser native configuration with maximal performance & privacy";

  hmConfig = {
    home.packages = [ braveNative ];
  };

  # Kebijakan sistem browser (berlaku universal)
  nixosConfig = {
    environment.etc."brave/policies/managed/policies.json".text = builtins.toJSON {
      ExtensionInstallForcelist = map (ext: ext.id) (
        commonChromiumExtensions
        ++ [
          { id = "einpaelgookohagofgnnkcfjbkkgepnp"; } # Random User-Agent (Switcher)
          { id = "nplimhmoanghlebhdiboeellhgmgommi"; } # Tab Groups Extension
          { id = "nkbihfbeogaeaoehlefnkodbefgpgknn"; } # Metamask
          { id = "bhhhlbepdkbapadjdnnojkbgioiodbic"; } # Solflare Wallet
          { id = "dmkamcknogkgcdfhhbddcghachkejeap"; } # Keplr Wallet
        ]
      );
      PasswordManagerEnabled = false;
      BrowserSignin = 0;
      RestoreOnStartup = 1;
      BraveAIChatEnabled = false;
      BraveP3AEnabled = false;
      BraveStatsPingEnabled = false;
      BraveWebDiscoveryEnabled = false;
      BraveWalletDisabled = true;
      BraveRewardsDisabled = true;
      BraveVPNDisabled = true;
    };
  };
}
