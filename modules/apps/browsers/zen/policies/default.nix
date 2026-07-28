# Zen Browser policies Preferences — imported by zen/default.nix
# Returns: { lock, lock-true, lock-false, lock-empty-string } → Preferences attrset
{
  lock,
  lock-true,
  lock-false,
  lock-empty-string,
}:
{
  # ==========================================
  # 1. Telemetri & Pengumpulan Data (Telemetry)
  # ==========================================
  "datareporting.healthreport.uploadEnabled" = lock-false;
  "datareporting.policy.dataSubmissionEnabled" = lock-false;
  "toolkit.telemetry.enabled" = lock-false;
  "toolkit.telemetry.unified" = lock-false;
  "toolkit.telemetry.server" = lock "data:,";
  "toolkit.telemetry.archive.enabled" = lock-false;
  "experiments.supported" = lock-false;
  "experiments.enabled" = lock-false;
  "experiments.activeExperiment" = lock-false;
  "network.allow-experiments" = lock-false;
  "browser.ping-centre.telemetry" = lock-false;
  "browser.newtabpage.activity-stream.feeds.telemetry" = lock-false;
  "browser.newtabpage.activity-stream.telemetry" = lock-false;

  # ==========================================
  # 2. Integrasi Pocket & Iklan (Pocket & Ads)
  # ==========================================
  "extensions.pocket.enabled" = lock-false;
  "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
  "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
  "browser.newtabpage.activity-stream.showSponsored" = lock-false;
  "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;

  # ==========================================
  # 3. Saran Pencarian & Rekomendasi (Recommendations)
  # ==========================================
  "browser.discovery.enabled" = lock-false;
  "extensions.getAddons.showPane" = lock-false;
  "extensions.htmlaboutaddons.recommendations.enabled" = lock-false;
  "browser.urlbar.suggest.searches" = lock-false;
  "browser.urlbar.quicksuggest.enabled" = lock-false;

  # ==========================================
  # 4. Halaman Awal & Startup (Startup & Onboarding)
  # ==========================================
  "browser.startup.page" = lock 3; # Restore session
  "browser.shell.checkDefaultBrowser" = lock-false;
  "extensions.autoDisableScopes" = lock 0;
  "extensions.enabledScopes" = lock 5;
  "toolkit.policies.perUserDir" = lock-true;
  "xpinstall.enabled" = lock-true;
  "zen.welcome-screen.seen" = lock-true;
  "zen.workspaces.continue-where-left-off" = lock-true;
  "browser.aboutwelcome.enabled" = lock-false;
  "browser.onboarding.enabled" = lock-false;
  "trailhead.firstrun.didSeeAboutWelcome" = lock-true;
  "browser.startup.firstrun.bundle" = lock-false;
  "browser.startup.homepage_override.mstone" = lock "ignore";

  # ==========================================
  # 5. Mesin Pencari Default (Search Engine)
  # ==========================================
  "browser.search.defaultenginename" = lock "DuckDuckGo";
  "browser.search.selectedEngine" = lock "DuckDuckGo";
  "browser.urlbar.placeholderName" = lock "DuckDuckGo";
  "browser.urlbar.placeholderName.private" = lock "DuckDuckGo";
  "browser.search.region" = lock "US";
  "browser.search.hiddenOneOffs" = lock "Google,Yahoo,Bing,Amazon.com,eBay,Wikipedia";

  # ==========================================
  # 6. Fitur Khas Zen Browser (Zen Specific)
  # ==========================================
  "zen.watermark.enabled" = lock-false; # Matikan splash screen saat startup
  "zen.view.compact.hide-toolbar" = lock-true; # Sembunyikan toolbar otomatis di mode compact
  "zen.theme.content-element-separation" = lock 0; # Setel border gap di sekitar jendela ke 0
  "zen.widget.linux.transparency" = lock-false; # Matikan dukungan transparansi UI di Linux
  "zen.view.sidebar-collapsed.hide-mute-button" = lock-true;
  "zen.theme.essentials-favicon-bg" = lock-true;
  "zen.ui.migration.compact-mode-button-added" = lock-true;
  "zen.view.compact.enable-at-startup" = lock-true;
  "zen.view.use-single-toolbar" = lock-false;
  "browser.aboutConfig.showWarning" = lock-false;
  "browser.preferences.config_warning.warningPasswordManager.dismissed" = lock-true;
  "intl.accept_languages" = lock "id,en-us";
  "zen.tab-unloader.enabled" = lock-false;

  # ==========================================
  # 7. Grafis & Performa (Graphics & Performance)
  # ==========================================
  "widget.dmabuf.force-enabled" = lock-true;
  "webgl.disabled" = lock-false;
  "browser.sessionhistory.max_entries" = lock 5;
  "browser.preferences.defaultPerformanceSettings.enabled" = lock-true;
  "browser.tabs.min_inactive_duration_before_unload" = lock 3600000; # 1 jam

  # ==========================================
  # 7.1. Jaringan & Performa (Network & Performance - Aligned with Firefox)
  # ==========================================
  "browser.sessionstore.restore_on_demand" = lock-true;
  "browser.sessionstore.restore_pinned_tabs_on_demand" = lock-true;
  "network.dns.disablePrefetch" = lock-true;
  "network.predictor.enabled" = lock-false;
  "network.http.speculative-parallel-limit" = lock 0;
  "browser.places.speculativeConnect.enabled" = lock-false;

  # ==========================================
  # 8. Privasi & Kredensial (Privacy & Credentials)
  # ==========================================
  "privacy.resistFingerprinting" = lock-false;
  "privacy.fingerprintingProtection" = lock-true;
  "privacy.fingerprintingProtection.overrides" =
    lock "+AllTargets,-CSSPrefersColorScheme,-ReduceTimerPrecision";
  "privacy.clearOnShutdown_v2.cookiesAndStorage" = lock-false;
  "media.peerconnection.enabled" = lock-true;
  "geo.enabled" = lock-true;
  "identity.fxaccounts.enabled" = lock-false;
  "signon.autofillForms" = lock-false;
  "signon.generation.enabled" = lock-false;
  "signon.rememberSignons" = lock-false;
  "extensions.formautofill.addresses.enabled" = lock-false;
  "extensions.formautofill.creditCards.enabled" = lock-false;

  # ==========================================
  # 9. Akselerasi Video Hardware (VA-API)
  # ==========================================
  "media.ffmpeg.vaapi.enabled" = lock-true;
  "gfx.webrender.all" = lock-true;
  "media.rdd-ffmpeg.enabled" = lock-true;
  "media.navigator.mediadatadecoder_vpx_enabled" = lock-true;
  "media.hardware-video-decoding.force-enabled" = lock-true;
}
