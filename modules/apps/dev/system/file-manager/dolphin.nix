{
  pkgs,
  userName,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.system.file-manager.dolphin";
  description = "Dolphin KDE file manager settings and packages";

  hmConfig =
    hmOpts:
    let
      inherit (hmOpts) lib;
    in
    {
      xdg = {
        configFile = {
          "baloofilerc".text = ''
            [Basic Settings]
            Indexing-Enabled=false
          '';

          "menus/applications.menu".text = ''
            <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
            <Menu>
              <Name>Applications</Name>
              <DefaultAppDirs/>
              <DefaultDirectoryDirs/>
              <DefaultMergeDirs/>
            </Menu>
          '';

          "dolphinrc".text = ''
            [DetailsMode]
            PreviewSize=22

            [General]
            GlobalViewProps=true
            Version=202

            [KFileDialog Settings]
            Places Icons Auto-resize=false
            Places Icons Static Size=22

            [MainWindow]
            MenuBar=Disabled
          '';
        };
      };

      home = {
        activation.updateKdeCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run env XDG_DATA_DIRS="/run/current-system/sw/share:/etc/profiles/per-user/${userName}/share:$XDG_DATA_DIRS" ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
        '';
        sessionVariables = {
          XDG_DATA_DIRS = "/run/current-system/sw/share:/etc/profiles/per-user/${userName}/share:$XDG_DATA_DIRS";
        };

        packages = with pkgs; [
          kdePackages.dolphin
          kdePackages.kio
          kdePackages.kio-extras
          kdePackages.breeze-icons
          kdePackages.qqc2-desktop-style
          kdePackages.ark

          zip
          unzip
          unrar
          p7zip
        ];
      };
    };
}
