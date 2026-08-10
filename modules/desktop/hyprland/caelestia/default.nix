_: {
  # Enable caelestia shell
  programs.caelestia = {
    enable = true;
    cli.enable = true;
    systemd.enable = false;
  };
}
