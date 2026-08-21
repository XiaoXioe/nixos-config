{
  pkgs,
  lib,
  selfLib,
}:

let
  distrosModule = import ../../_lib/modules/distrobox-helper/distros.nix { inherit lib; };
  detectPkgMgrBash = distrosModule.mkDetectPkgManagerBash distrosModule.distroDetectionRules;

  rawScript = builtins.readFile ./dbox.sh;
  scriptText = lib.replaceStrings [ "@DETECT_PKG_MGR_BASH@" ] [ detectPkgMgrBash ] rawScript;

  dboxPkgApp = selfLib.mkApp pkgs "dbox-pkg" scriptText [
    pkgs.distrobox
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gawk
  ];
in
pkgs.runCommand "dbox-pkg-tools" { } ''
  mkdir -p $out/bin
  ln -s ${dboxPkgApp} $out/bin/dbox-pkg
  ln -s ${dboxPkgApp} $out/bin/dbox
  ln -s ${dboxPkgApp} $out/bin/dbox-apt
  ln -s ${dboxPkgApp} $out/bin/dbox-pacman
  ln -s ${dboxPkgApp} $out/bin/dbox-dnf
  ln -s ${dboxPkgApp} $out/bin/dbox-apk
  ln -s ${dboxPkgApp} $out/bin/dbox-zypper
  ln -s ${dboxPkgApp} $out/bin/dbox-xbps
''
