# Locale, timezone, and documentation settings.
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.core.locale;
in
{
  options.my.system.core.locale = {
    enable = lib.mkEnableOption "locale, timezone, and base system settings";
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

  config = lib.mkIf cfg.enable {
    time.timeZone = cfg.timezone;
    i18n.defaultLocale = cfg.locale;

    fonts.fontDir.enable = true;

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
