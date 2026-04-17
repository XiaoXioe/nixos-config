{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.vpn-auto;
  vpnDir = ../../../secrets/vpn-files;
  vpnFilesRaw = if builtins.pathExists vpnDir then builtins.readDir vpnDir else {};
  vpnFiles = builtins.filter (name: vpnFilesRaw.${name} == "regular" && lib.hasSuffix ".conf" name) (builtins.attrNames vpnFilesRaw);
in
{
  options.my.services.vpn-auto = {
    enable = selfLib.mkBoolOpt false "automatic ProtonVPN import service";
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
    systemd.services.nm-import-proton = {
      description = "Auto import VPNs to NetworkManager";
      after = [
        "NetworkManager.service"
        "sops-nix.service"
      ];
      wants = [ "NetworkManager.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        ${lib.concatMapStringsSep "\n" (fileName: ''
          VPN_ID="${lib.removeSuffix ".conf" fileName}"
          
          for i in {1..10}; do
            if [ -f ${config.sops.secrets.${fileName}.path} ]; then
              break
            fi
            sleep 1
          done
          
          if ! ${pkgs.networkmanager}/bin/nmcli connection show "$VPN_ID" > /dev/null 2>&1; then
            ${pkgs.networkmanager}/bin/nmcli connection import type wireguard file ${config.sops.secrets.${fileName}.path}
            
            # nmcli assigns connection ID based on the file basename
            ${pkgs.networkmanager}/bin/nmcli connection modify "$VPN_ID" connection.autoconnect no || true
          fi
        '') vpnFiles}
      '';
    };
  };
}
