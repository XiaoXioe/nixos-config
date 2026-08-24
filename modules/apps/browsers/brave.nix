{
  selfLib,
  pkgs,
  ...
}:

let
  inherit (selfLib.browserAddonsFor { inherit pkgs; }) commonChromiumExtensions;
in
selfLib.mkModule {
  name = "apps.browsers.brave";
  description = "Brave browser via Nix binary cache — builtins.fetchClosure with Home Manager configuration";

  hmConfig = {
    programs.brave = {
      enable = true;
      package = selfLib.fetchCachePinned pkgs "brave";
      commandLineArgs = [
        "--password-store=gnome-libsecret"
        "--enable-gpu-rasterization"
        "--ignore-gpu-blocklist"
        "--enable-features=WebUIDarkMode,Containers"
        "--disable-gpu-driver-bug-workarounds"
        "--disable-reading-from-canvas"
        "--no-pings"
      ];
      extensions = [
        { id = "einpaelgookohagofgnnkcfjbkkgepnp"; } # Random User-Agent (Switcher)
        { id = "nplimhmoanghlebhdiboeellhgmgommi"; } # Tab Groups Extension
        { id = "nkbihfbeogaeaoehlefnkodbefgpgknn"; } # Metamask
        { id = "bhhhlbepdkbapadjdnnojkbgioiodbic"; } # Solflare Wallet
        { id = "dmkamcknogkgcdfhhbddcghachkejeap"; } # Keplr Wallet
      ]
      ++ commonChromiumExtensions;
    };
  };

  # Kebijakan sistem browser (berlaku universal, tidak bergantung pada source package)
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
