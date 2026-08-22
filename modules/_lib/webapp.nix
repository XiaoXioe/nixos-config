# WebApp PWA builder: generates a desktop package (exec binary + .desktop launcher)
# that runs a web application in app/PWA mode using Chromium or Brave or Firefox.
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
      browser ? "brave",
      wmClass ? null,
      extraFlags ? [ ],
      ...
    }:
    let
      isDerivation = lib.isDerivation browser;

      browserName =
        if isDerivation then
          (browser.meta.mainProgram or (browser.pname or (lib.getName browser)))
        else
          browser;

      isFirefoxLike = lib.elem browserName [
        "firefox"
        "firefox-esr"
        "librewolf"
        "zen"
      ];

      flagsString = lib.concatStringsSep " " extraFlags;
      flagsParam = if flagsString != "" then " " + flagsString else "";

      browserExe = if isDerivation then lib.getExe browser else browser;

      execCmd =
        if isFirefoxLike then
          "${browserExe} --new-instance --class=\"${name}\" --profile /tmp/${name}-pwa${flagsParam} \"${url}\" \"\$@\""
        else
          "${browserExe} --app=\"${url}\"${flagsParam} \"\$@\"";

      execApp = pkgs.writeShellScriptBin name ''
        exec ${execCmd}
      '';

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
