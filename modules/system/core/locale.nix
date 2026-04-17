{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.locale;
in
{
  options.my.system.locale = {
    enable = selfLib.mkBoolOpt false "Locale, timezone, and base system settings";
    timezone = selfLib.mkOpt lib.types.str "Asia/Jakarta" "System timezone";
    locale = selfLib.mkOpt lib.types.str "en_US.UTF-8" "Default locale";
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = cfg.timezone;
    i18n.defaultLocale = cfg.locale;

    fonts.fontDir.enable = true;
    programs.fuse.userAllowOther = true;
    programs.fish.enable = true;

    # Mematikan pembuatan dokumentasi sistem untuk mempercepat rebuild
    documentation = {
      enable = false;
      #man.cache.enable = false;
      dev.enable = false;
      man.enable = false;
      info.enable = false;
      doc.enable = false;
      nixos.enable = false;
    };
  };
}
