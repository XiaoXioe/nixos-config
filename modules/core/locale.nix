# Locale, timezone, and documentation settings.
{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "core.locale";
  options = {
    timezone = lib.mkOption {
      type = lib.types.str;
      default = "Asia/Jakarta";
      description = "System timezone.";
    };
    locale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "Default system locale.";
    };
  };

  nixosConfig =
    let
      cfg = config.my.core.locale;
    in
    {
      time.timeZone = cfg.timezone;
      i18n.defaultLocale = cfg.locale;

      # Disable documentation generation to speed up rebuilds.
      documentation = {
        enable = false;
        man.cache.enable = false;
        dev.enable = false;
        man.enable = false;
        info.enable = false;
        doc.enable = false;
        nixos.enable = false;
      };
    };
}
