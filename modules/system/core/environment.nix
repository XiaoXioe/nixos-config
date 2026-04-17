{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.environment;
in
{
  options.my.system.environment = {
    enable = selfLib.mkBoolOpt false "Environments configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.variables = {
      EDITOR = "sublime -w";

      # QT_QPA_PLATFORMTHEME diset per-DE di modul masing-masing
      # (niri.nix pakai "kde", KDE Plasma sudah handle sendiri)
      PLASMA_USE_QT_SCALING = "1";
      GSK_RENDERER = "gl";

      # Opsional: Memaksa aplikasi KDE untuk langsung mati saat crash,
      # tanpa mencoba memanggil GUI pelapor crash
      KCRASH_CORE_PATTERN_RAISE = "1";
    };

    environment.sessionVariables = {
      MESA_LOADER_DRIVER_OVERRIDE = "crocus";
      LIBVA_DRIVER_NAME = "i965";
      VAAPI_MPEG4_ENABLED = "true";

      # Pastikan Firefox berjalan di mode Wayland murni
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Membuat file kebijakan Brave di level sistem operasi
    environment.etc."brave/policies/managed/policies.json".text = builtins.toJSON {
      # === Telemetry & Bloat ===
      BraveP3AEnabled = false;
      BraveStatsPingEnabled = false;
      BraveWebDiscoveryEnabled = false;
      BraveRewardsDisabled = true;
      BraveWalletDisabled = true;
      BraveVPNDisabled = true;
      BraveAIChatEnabled = false;
      BraveNewsDisabled = true;
      BraveTalkDisabled = true;
      BraveSpeedreaderEnabled = false;
      BraveWaybackMachineEnabled = false;
      BravePlaylistEnabled = false;

      MetricsReportingEnabled = false;

      # === Privacy & Security ===
      BackgroundModeEnabled = false;
      BrowserGuestModeEnabled = false;
      IncognitoModeAvailability = 0; # izinkan Private + Tor

      DefaultGeolocationSetting = 2;
      DefaultNotificationsSetting = 2;
      DefaultSensorsSetting = 2;

      DefaultImagesSetting = 1;
      DefaultJavaScriptSetting = 1;
      DefaultPopupsSetting = 2;

      # === Fitur Tambahan ===
      SyncDisabled = true; # matikan sync total
      # ExtensionInstallBlocklist = [ "*" ];
      ExtensionInstallForcelist = [
        # Bitwarden
        "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx"
        # Video DownloadHelper
        "lmjnegcaeklhafolokijcfjliaokphfk;https://clients2.google.com/service/update2/crx"
        # Tema Catppuccin Macchiato
        "cmpdlhmnmjhihmcfnigoememnffkimlk;https://clients2.google.com/service/update2/crx"
        # enhanced-h264ify
        "omkfmpieigblcllmkgbflkikinpkodlk;https://clients2.google.com/service/update2/crx"
        # Auto Tab Discard
        "jhnleheckmknfcgijgkadoemagpecfol;https://clients2.google.com/service/update2/crx"
        # SponsorBlock
        "mnjggcdmjocbbbhaepdhchncahnbgone;https://clients2.google.com/service/update2/crx"
      ];
      TranslateEnabled = false;
      BuiltInDnsClientEnabled = false;
      PasswordManagerEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      # === Search Engine (paksa Brave Search) ===
      DefaultSearchProviderEnabled = true;
      DefaultSearchProviderSearchURL = "https://search.brave.com/search?q={searchTerms}";
      DefaultSearchProviderSuggestURL = "https://search.brave.com/search?q={searchTerms}";
      DefaultSearchProviderNewTabURL = "https://search.brave.com/";

      HardwareAccelerationModeEnabled = true;
      HighEfficiencyModeEnabled = true;

      # === Spellcheck ===
      SpellcheckEnabled = true;
      SpellcheckLanguage = [
        "id"
        "en-US"
      ];
    };
  };
}
