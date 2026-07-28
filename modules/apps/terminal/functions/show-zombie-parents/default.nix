{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.functions.show-zombie-parents";
  description = "Identify zombie/defunct processes";

  hmConfig = hmOpts: {
    home.packages = [
      (
        (selfLib.shell {
          inherit pkgs;
          lib = pkgs.lib;
        }).mkApp
        "show-zombie-parents"
        ''
          ZOMBIE_PPIDS=$(ps -A -ostat,ppid | grep -e '[zZ]' | awk '{ print $2 }' | uniq)
          if [ -n "$ZOMBIE_PPIDS" ]; then echo "$ZOMBIE_PPIDS" | xargs ${pkgs.procps}/bin/ps -p; else echo "No zombies."; fi
        ''
        [ ]
      )
    ];
  };
}
