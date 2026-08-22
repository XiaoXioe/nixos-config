{
  pkgs,
  selfLib,
  lib,
  ...
}:

let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      urllib3
    ]
  );

  updateNativeApps = pkgs.stdenv.mkDerivation {
    pname = "update-native-apps";
    version = "1.0.0";
    src = ./scripts;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/lib/update-native-apps $out/bin
      cp -r * $out/lib/update-native-apps/
      makeWrapper ${pythonEnv}/bin/python3 $out/bin/update-native-apps \
        --add-flags "$out/lib/update-native-apps/main.py" \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.nix
            pkgs.fzf
            pkgs.gh
            pkgs.nixfmt
          ]
        }
    '';
  };
in
selfLib.mkModule {
  name = "apps.dev.nix.apps-updater";
  description = "Modular automatic and interactive upstream version updater for native apps (update-native-apps / unau)";

  hmConfig = {
    home.packages = [
      updateNativeApps
      (pkgs.writeShellScriptBin "unau" ''
        exec update-native-apps "$@"
      '')
    ];
  };
}
