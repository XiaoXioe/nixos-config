{ lib, ... }:

let
  splitName = name: lib.splitString "." name;

  sanitizePath =
    p:
    if (builtins.match ".*\\.\\..*" p != null || lib.hasPrefix "/" p) then
      builtins.abort "Security Violation: Path traversal or absolute path detected in Flatpak guest configuration: ${p}"
    else
      p;

  getNativePkg =
    appVal:
    let
      nativePkg = appVal.nativePkgs or (appVal.native.package or (appVal.package or null));
      nativePackages =
        if nativePkg == null then [ ] else (if builtins.isList nativePkg then nativePkg else [ nativePkg ]);
      realNativePkg = if nativePackages != [ ] then builtins.elemAt nativePackages 0 else null;
    in
    {
      inherit nativePackages realNativePkg;
    };

  isAppEnabled =
    {
      name,
      flatpakCfg,
      config,
      singleAppInfo,
      enableState,
      ...
    }:
    appId:
    let
      optionPath = splitName name;
      isSingleApp = singleAppInfo.isSingleApp;
      singleAppId = singleAppInfo.singleAppId;
      appVal = flatpakCfg.${appId};
    in
    if !(appVal.enable or true) then
      false
    else if isSingleApp && appId == singleAppId then
      enableState
    else
      let
        appOptPath = optionPath ++ [
          "flatpaks"
          appId
          "enable"
        ];
      in
      if lib.hasAttrByPath appOptPath config.my then lib.getAttrFromPath appOptPath config.my else true;

  useFlatpak =
    ctx@{
      name,
      flatpakCfg,
      config,
      singleAppInfo,
      enableState,
      ...
    }:
    appId:
    let
      optionPath = splitName name;
      isSingleApp = singleAppInfo.isSingleApp;
      singleAppId = singleAppInfo.singleAppId;
      appVal = flatpakCfg.${appId};
      appOptPath =
        if isSingleApp && appId == singleAppId then
          optionPath
          ++ [
            "flatpak"
            "enable"
          ]
        else
          optionPath
          ++ [
            "flatpaks"
            appId
            "flatpak"
            "enable"
          ];
    in
    isAppEnabled ctx appId
    && (
      if lib.hasAttrByPath appOptPath config.my then
        lib.getAttrFromPath appOptPath config.my
      else
        appVal.flatpak or true
    );
in
{
  inherit
    splitName
    sanitizePath
    getNativePkg
    isAppEnabled
    useFlatpak
    ;
}
