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
      EDITOR = "zeditor -w";

      # QT_QPA_PLATFORMTHEME diset per-DE di modul masing-masing
      # (niri.nix pakai "kde", KDE Plasma sudah handle sendiri)
      PLASMA_USE_QT_SCALING = "1";
      GSK_RENDERER = "gl";

      # Opsional: Memaksa aplikasi KDE untuk langsung mati saat crash,
      # tanpa mencoba memanggil GUI pelapor crash
      KCRASH_CORE_PATTERN_RAISE = "1";

      NIXOS_OZONE_WL = "1";
    };

    environment.sessionVariables = {
      MESA_LOADER_DRIVER_OVERRIDE = "crocus";
      LIBVA_DRIVER_NAME = "i965";
      VAAPI_MPEG4_ENABLED = "true";

      # Pastikan Firefox berjalan di mode Wayland murni
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}
