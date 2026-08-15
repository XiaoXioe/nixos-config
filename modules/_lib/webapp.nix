# WebApp PWA builder: generates a desktop package (exec binary + .desktop launcher)
# that runs a web application in app/PWA mode using Chromium or Brave.
# Supports native package name (string), Flatpak app ID, or direct Nix package object (derivation).
{ lib, pkgs }:

{
  mkWebApp =
    {
      name,
      desktopName,
      url,
      icon ? "chromium",
      categories ? [
        "Network"
        "WebBrowser"
        "Email"
      ],
      comment ? "",
      browser ? "chromium",
      wmClass ? null,
      osConfig ? null,
      extraFlags ? [ ],
    }:
    let
      # Check if browser is a package derivation object
      isDerivation = lib.isDerivation browser;

      # Mapping from short browser names to their Flatpak IDs
      flatpakIds = {
        brave = "com.brave.Browser";
        chromium = "org.chromium.Chromium";
        firefox = "org.mozilla.firefox";
        librewolf = "io.gitlab.librewolf-community";
      };

      # Browser name string (for detection and fallback)
      browserName =
        if isDerivation then
          (browser.meta.mainProgram or (browser.pname or (lib.getName browser)))
        else
          browser;

      # Check if browser is Firefox-like (uses different launch flags)
      isFirefoxLike = lib.elem browserName [
        "firefox"
        "librewolf"
        "org.mozilla.firefox"
        "io.gitlab.librewolf-community"
      ];

      # If it's a string, check if it's a Flatpak ID (contains dot)
      isFlatpakRaw = if isDerivation then false else lib.strings.hasInfix "." browser;

      # Resolve whether it should run as a Flatpak based on the active NixOS configuration (osConfig)
      isFlatpak =
        if isDerivation then
          false
        else if isFlatpakRaw then
          true
        else if osConfig != null then
          let
            # Check if my.apps.browsers.${browser} is enabled and uses flatpak
            isModuleEnabled =
              if lib.hasAttrByPath [ "my" "apps" "browsers" browser "enable" ] osConfig then
                osConfig.my.apps.browsers.${browser}.enable
              else
                false;
            isFlatpakEnabled =
              if lib.hasAttrByPath [ "my" "apps" "browsers" browser "flatpak" "enable" ] osConfig then
                osConfig.my.apps.browsers.${browser}.flatpak.enable
              else
                false;
          in
          isModuleEnabled && isFlatpakEnabled
        else
          false;

      # Determine the actual browser string/ID to run
      runBrowser = if isFlatpak && !isFlatpakRaw then (flatpakIds.${browser} or browser) else browser;

      # Format extraFlags list to a single string parameter if not empty
      flagsString = lib.concatStringsSep " " extraFlags;
      flagsParam = if flagsString != "" then " " + flagsString else "";

      # Resolve executable path for native browser
      nativeBrowserPkg = if isDerivation then browser else pkgs.${browser};
      nativeBrowserExe = lib.getExe nativeBrowserPkg;

      # Determine the launch command to avoid string coercing null at Nix evaluation time
      execCmd =
        if isFlatpak then
          if isFirefoxLike then
            "${pkgs.flatpak}/bin/flatpak run ${runBrowser} --new-instance --class=\"${name}\"${flagsParam} \"${url}\" \"\$@\""
          else
            "${pkgs.flatpak}/bin/flatpak run ${runBrowser} --app=\"${url}\"${flagsParam} \"\$@\""
        else if isFirefoxLike then
          "${nativeBrowserExe} --new-instance --class=\"${name}\" --profile /tmp/${name}-pwa${flagsParam} \"${url}\" \"\$@\""
        else
          "${nativeBrowserExe} --app=\"${url}\"${flagsParam} \"\$@\"";

      execApp = pkgs.writeShellScriptBin name ''
        exec ${execCmd}
      '';

      # Ensure categories is a list of strings
      categoriesList = if builtins.isList categories then categories else [ categories ];

      desktopItem = pkgs.makeDesktopItem {
        inherit
          name
          desktopName
          comment
          icon
          ;
        categories = categoriesList;
        exec = "${execApp}/bin/${name} %U";
        terminal = false;
        type = "Application";
        startupWMClass = if wmClass != null then wmClass else "";
      };
    in
    pkgs.symlinkJoin {
      inherit name;
      paths = [
        execApp
        desktopItem
      ];
    };
}
