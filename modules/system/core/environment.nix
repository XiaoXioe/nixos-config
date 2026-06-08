{
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.core.environment;
in
{
  options.my.system.core.environment = {
    enable = lib.mkEnableOption "Environments configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.variables = {
      EDITOR = "codium -w";

      # QT_QPA_PLATFORMTHEME diset per-DE di modul masing-masing
      # (niri.nix pakai "kde", KDE Plasma sudah handle sendiri)
      PLASMA_USE_QT_SCALING = "1";
      GSK_RENDERER = "gl";

      # Force KDE apps to terminate immediately on crash,
      # tanpa mencoba memanggil GUI pelapor crash
      KCRASH_CORE_PATTERN_RAISE = "1";

      NIXOS_OZONE_WL = "1";

      # 9Router AI gateway
      NINEROUTER_URL = "http://localhost:20128";
    };

    environment.sessionVariables = {
      MESA_LOADER_DRIVER_OVERRIDE = "crocus";
      LIBVA_DRIVER_NAME = "i965";
      VAAPI_MPEG4_ENABLED = "true";

      # Force Firefox to run in native Wayland mode
      MOZ_ENABLE_WAYLAND = "1";
    };

    environment.etc."brave/policies/managed/policies.json".text = builtins.toJSON {
      PasswordManagerEnabled = false;
      BrowserSignin = 0;
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
