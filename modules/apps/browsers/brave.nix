{
  selfLib,
  pkgs,
  ...
}:

let
  inherit (selfLib.browserAddonsFor { inherit pkgs; }) commonChromiumExtensions;

  # ── Brave dari Nix binary cache (cache.nixos.org) ──────────────────────────
  # Menggunakan builtins.fetchClosure — Hydra-built, Nix-patched RPATHs.
  # Tidak butuh nix-ld, patchelf, atau LD_LIBRARY_PATH manipulation.
  # Seluruh closure (glibc, gtk, dll.) ter-fetch otomatis.
  # Zero Re-Download: store path stabil meski `nix flake update` dijalankan.
  braveStore = selfLib.fetchCachePinned "brave";

  # symlinkJoin: pertahankan seluruh brave (desktop entry, icons, man pages, dll.)
  # lalu wrap binary dengan extra flags via makeWrapper.
  # Output adalah paket lengkap — tidak ada desktop integration yang hilang.
  brave = pkgs.symlinkJoin {
    name = "brave";
    paths = [ braveStore ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/brave" \
        --add-flags "--password-store=gnome-libsecret" \
        --add-flags "--enable-gpu-rasterization" \
        --add-flags "--ignore-gpu-blocklist" \
        --add-flags "--enable-features=WebUIDarkMode,Containers" \
        --add-flags "--disable-gpu-driver-bug-workarounds" \
        --add-flags "--disable-reading-from-canvas" \
        --add-flags "--no-pings"
    '';
  };
in
selfLib.mkModule {
  name = "apps.browsers.brave";
  description = "Brave browser via Nix binary cache — builtins.fetchClosure, zero nixpkgs closure rebuild";

  hmConfig = {
    home.packages = [ brave ];
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
