{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.utilities.functions.show-zombie-parents";
  description = "Identify zombie/defunct processes";

  hmConfig = {
    home.packages = [
      (selfLib.mkApp pkgs "show-zombie-parents" ''
        ZOMBIE_PPIDS=$(ps -A -ostat,ppid | grep -e '[zZ]' | awk '{ print $2 }' | uniq)
        if [ -n "$ZOMBIE_PPIDS" ]; then echo "$ZOMBIE_PPIDS" | xargs ${pkgs.procps}/bin/ps -p; else echo "No zombies."; fi
      '' [ ])
    ];
  };
}
