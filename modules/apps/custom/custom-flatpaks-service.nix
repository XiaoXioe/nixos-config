{ pkgs, lib, ... }:

{
  systemd.user.services.install-custom-flatpaks = {
    Unit = {
      Description = "Download and install custom private flatpaks";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "install-custom-flatpaks" ''
        set -eu
        mkdir -p $HOME/.cache/custom-flatpaks
        cd $HOME/.cache/custom-flatpaks

        echo "Downloading flatpak bundles from private release..."
        ${pkgs.gh}/bin/gh release download v1.0.0 -R XiaoXioe/flatpak-packages --clobber || true

        if [ -f "com.portswigger.BurpSuitePro.flatpak" ]; then
          echo "Installing BurpSuitePro..."
          ${pkgs.flatpak}/bin/flatpak install --user -y com.portswigger.BurpSuitePro.flatpak || true
        fi

        if [ -f "io.github.xiaoyouchr.GhostDownloader.flatpak" ]; then
          echo "Installing GhostDownloader..."
          ${pkgs.flatpak}/bin/flatpak install --user -y io.github.xiaoyouchr.GhostDownloader.flatpak || true
        fi
      ''}";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
